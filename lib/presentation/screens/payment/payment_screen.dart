import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on_driver/core/utils/translate.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../../domain/entities/realtime_ride_request.dart';
import '../../cubits/payment/payment_cubit.dart';
import '../../cubits/realtime/listen_ride_request_booking_id_cubit.dart';
import '../../cubits/realtime/listen_ride_request_cubit.dart';
import '../../cubits/realtime/manage_driver_cubit.dart';
import '../../widgets/custome_review_widget.dart';

class PaymentScreen extends StatefulWidget {
  final RealTimeRideRequest rideRequest;

  const PaymentScreen({super.key, required this.rideRequest});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String paymentMethod = "";

  @override
  void initState() {
    super.initState();

    context.read<ListenRideRequestCubit>().resetListenRideRequest();
    context
        .read<GetPaymentStatusAndMethodCubit>()
        .listenToPaymentStatusAndMethod(
          rideId: widget.rideRequest.rideId ?? "",
        );
  }

  void _onProceed(BuildContext context, PaymentMethod? method) {
    if (method == null) {
      showErrorToastMessage("Please select a payment method");
      return;
    }

    if (method == PaymentMethod.cash) {
      _showConfirmationDialog(context, "cash",
          "Has the payment been received by cash? If yes, click to proceed.");
    } else if (method == PaymentMethod.online) {
      _showConfirmationDialog(
          context, "online", "Are you sure you want to pay online?");
    }
  }

  void _showConfirmationDialog(
      BuildContext context, String method, String text) {
    showDialog(
      context: context,
      builder: (_) => PaymentConfirmationDialogs(
        onPressed: () async {
          Navigator.pop(context);
          final bookingId =
              context.read<UpdateDriverParameterCubit>().state.bookingId;

          await context
              .read<UpdatePaymentStatusByDriverCubit>()
              .updatePaymentStatusByDriver(
                context: context,
                bookingId: bookingId,
                paymentMethod: method,
              );
        },
        text: text,
      ),
    );
    setState(() {
      paymentMethod = method;
    });
  }

  Future<void> _completeRideProcess(BuildContext context) async {
    final rideId = widget.rideRequest.rideId;

    completeRide(driverId: driverId, rideId: rideId ?? "");

    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({'ride_request': {}, 'rideStatus': 'available'});

    } catch (e) {
      //

    }

    if (isOpenBottomsheet) return;

    isOpenBottomsheet = true;
      // ignore_for_file: use_build_context_synchronously
    showModalBottomSheet(
      barrierColor: blackColor.withAlpha(64),
      elevation: 0,
      context: context,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomReviewWidget(
        rideRequest: widget.rideRequest,
      ),
    );
  }

  bool isOpenBottomsheet = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: whiteColor,
        appBar: CustomAppBar(
          title: "Trip Summary",
          onBackTap: () async {

            _onProceed(context, PaymentMethod.cash);
          },
        ),
        body: BlocListener<GetPaymentStatusAndMethodCubit, Map<String, String>>(
          listener: (context, state) async {
            setState(() => paymentMethod = state["paymentMethod"] ?? "");
            if (state["paymentStatus"] == "collected") {
              await _completeRideProcess(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocBuilder<PaymentCubit, PaymentMethod?>(
              builder: (context, selectedMethod) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildCustomerInfo(context),
                    const SizedBox(height: 20),
                    BlocConsumer<UpdatePaymentStatusByDriverCubit,
                        UpdatePaymentStatusByDriverState>(
                      builder: (context, state) {
                        return _buildActionButton(context, selectedMethod);
                      },
                      listener: (context, state) async {
                        if (state is UpdatePaymentLoading) {
                          Widgets.showLoader(context);
                        }
                        if (state is UpdatePaymentSuceess) {
                          Widgets.hideLoder(context);
                          context
                              .read<GetListenRideRequestBookingIdCubit>()
                              .updatePaymentStatus(
                                rideId: widget.rideRequest.rideId ?? "",
                                newStatus: "collected",
                              );
                          await _completeRideProcess(context);
                        } else if (state is UpdatePaymentFailure) {
                          Widgets.hideLoder(context);
                          showErrorToastMessage(state.paymentMessage??"");
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context) {
    return Column(
      children: [
        ClipOval(
          child: SizedBox(
            height: 60,
            width: 60,
            child: myNetworkImage(widget.rideRequest.customer?.userPhoto ?? ""),
          ),
        ),
        const SizedBox(height: 8,),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call, size: 16, color: themeColor),
            const SizedBox(width: 8),
            Text(widget.rideRequest.customer?.userPhone ?? "",
                style: regular(context)),
          ],
        ),
        const SizedBox(height: 15),
        _buildStatusTag(context),
        const SizedBox(height: 15),
        Text(
          "${"Please collect fare from".translate(context)} \n ${widget.rideRequest.customer?.userName ?? ""}.",
          style: heading3Grey1(context).copyWith(fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Divider(color: grey5),
        const SizedBox(height: 30),
        _buildLocationDetails(context),
        const SizedBox(height: 20),
        Text("$currency ${widget.rideRequest.travelCharges}",
            style: heading1(context).copyWith(color: greentext)),
      ],
    );
  }

  Widget _buildStatusTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: greentext,
        border: Border.all(color: greentext),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: whiteColor, size: 18),
          const SizedBox(width: 10),
          Text("RIDE COMPLETE".translate(context),
              style: regular(context).copyWith(color: whiteColor,fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLocationDetails(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
       ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side timeline
          Column(
            children: [
              // Pickup icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.my_location, // modern pickup icon
                  size: 20,
                  color: Colors.green,
                ),
              ),
              // Line between
              Container(
                width: 2,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade200, Colors.red.shade200],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Drop icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag, // modern drop icon
                  size: 20,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Right side text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup
                Text(
                  "Pickup".translate(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.rideRequest.pickupLocation?.pickupAddress ?? "",
                  style:heading3Grey1(context).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Drop
                Text(
                  "Drop".translate(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.rideRequest.dropoffLocation?.dropoffAddress ?? "",
                  style: heading3Grey1(context).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionButton(
      BuildContext context, PaymentMethod? selectedMethod) {
    if (paymentMethod == "cash" || paymentMethod == "") {
      return CustomsButtons(
        textColor: blackColor,
        backgroundColor: themeColor,
        onPressed: () => _onProceed(context, selectedMethod),
        text: "Collect",
      );
    } else {
      return CustomsButtons(
        textColor: blackColor,
        backgroundColor: themeColor,
        onPressed: () {},
        text: "Waiting for payment...",
      );
    }
  }
}

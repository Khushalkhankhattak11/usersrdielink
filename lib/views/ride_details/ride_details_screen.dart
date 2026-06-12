import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/home_content.dart';
import '../../viewmodels/ride_details_view_model.dart';

class RideDetailsScreen extends StatelessWidget {
  const RideDetailsScreen({
    super.key,
    required this.ride,
    required this.onBack,
  });

  final RideOption ride;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RideDetailsViewModel>();
    viewModel.configureForRide(ride);

    return Scaffold(
      backgroundColor: DetailsColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 576),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RoutePreview(ride: ride),
                        const SizedBox(height: 24),
                        _DriverVehicleCard(ride: ride),
                        const SizedBox(height: 24),
                        _SeatSelection(viewModel: viewModel),
                        const SizedBox(height: 24),
                        _FareBreakdown(viewModel: viewModel),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BookingFooter(
        viewModel: viewModel,
        ride: ride,
        onBooked: onBack,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: DetailsColors.primary),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ride Details',
              style: TextStyle(
                color: DetailsColors.primary,
                fontSize: 20,
                height: 28 / 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const CircleAvatar(
              radius: 20,
              backgroundColor: DetailsColors.surfaceLow,
              child: Icon(Icons.person, color: DetailsColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview({required this.ride});

  final RideOption ride;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            const Positioned.fill(child: _MapPreviewArt()),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: DetailsColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DetailsColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _RoutePoint(label: 'FROM', value: _cityName(ride.from)),
                      const Spacer(),
                      const Icon(
                        Icons.trending_flat,
                        color: DetailsColors.secondary,
                      ),
                      const Spacer(),
                      _RoutePoint(
                        label: 'TO',
                        value: _cityName(ride.to),
                        alignEnd: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cityName(String value) => value.split(' ').first;
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DetailsColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: DetailsColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DriverVehicleCard extends StatelessWidget {
  const _DriverVehicleCard({required this.ride});

  final RideOption ride;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: const [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: DetailsColors.secondaryFixed,
                    child: Icon(Icons.person, color: DetailsColors.secondary),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: DetailsColors.secondary,
                      child: Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: const [
                        Text(
                          'Ahmed Ali',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _SmallBadge('Top Rated'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                        SizedBox(width: 4),
                        Text(
                          '4.8 (124 Rides)',
                          style: TextStyle(
                            color: DetailsColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chat, color: DetailsColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: DetailsColors.outlineVariant),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TierLabel('Standard Tier'),
                    const SizedBox(height: 8),
                    Text(
                      ride.vehicle
                          .replaceAll('2020', '')
                          .replaceAll('2021', ''),
                      style: const TextStyle(
                        fontSize: 20,
                        height: 28 / 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'White • Model 2022 • LE-4592',
                      style: TextStyle(color: DetailsColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 8,
                      children: [
                        _FeatureChip(icon: Icons.ac_unit, label: 'AC'),
                        _FeatureChip(icon: Icons.luggage, label: '2 Bags'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const SizedBox(width: 132, height: 128, child: _CarPreviewArt()),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeatSelection extends StatelessWidget {
  const _SeatSelection({required this.viewModel});

  final RideDetailsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final seatIds = viewModel.seatIds;
    final gridItems = seatIds.length + 1;
    final rowCount = (gridItems / 2).ceil();

    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Select Seats',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              _DangerBadge(
                viewModel.isRideFull
                    ? 'Full'
                    : '${viewModel.remainingSeatCount} Seats Left',
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: viewModel.isRideFull
                ? null
                : viewModel.bookFullCarForFamily,
            icon: const Icon(Icons.family_restroom),
            label: const Text('Book Full Car for Family'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: DetailsColors.secondary,
              side: const BorderSide(color: DetailsColors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 168,
                height: (rowCount * 48) + ((rowCount - 1) * 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 48,
                  childAspectRatio: 1,
                  children: [
                    const _SeatBox(
                      key: ValueKey('seat_driver'),
                      state: SeatState.disabled,
                      tooltip: 'Driver seat',
                    ),
                    for (final seatId in seatIds)
                      _SeatBox(
                        key: ValueKey('seat_$seatId'),
                        state: _seatStateFor(viewModel, seatId),
                        tooltip:
                            '${viewModel.seatLabel(seatId)} - ${viewModel.seatLocation(seatId)}',
                        onTap: () => viewModel.toggleSeat(seatId),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 8,
            children: [
              _SeatLegend(color: DetailsColors.secondary, label: 'Available'),
              _SeatLegend(color: DetailsColors.surfaceHigh, label: 'Booked'),
              _SeatLegend(
                color: DetailsColors.secondaryContainer,
                label: 'Selected',
              ),
            ],
          ),
        ],
      ),
    );
  }

  SeatState _seatStateFor(RideDetailsViewModel viewModel, String seatId) {
    if (viewModel.isSeatBooked(seatId)) {
      return SeatState.booked;
    }
    if (viewModel.isSeatSelected(seatId)) {
      return SeatState.selected;
    }
    return SeatState.available;
  }
}

enum SeatState { disabled, booked, available, selected }

class _SeatBox extends StatelessWidget {
  const _SeatBox({
    super.key,
    required this.state,
    required this.tooltip,
    this.onTap,
  });

  final SeatState state;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = state == SeatState.selected;
    final isAvailable = state == SeatState.available;
    final isBooked = state == SeatState.booked;
    final isDisabled = state == SeatState.disabled;

    final color = isSelected
        ? DetailsColors.secondaryContainer
        : isBooked
        ? DetailsColors.surfaceHigh
        : DetailsColors.surfaceLow;
    final borderColor = isAvailable || isSelected
        ? DetailsColors.secondary
        : DetailsColors.outlineVariant;
    final icon = isBooked
        ? Icons.person
        : isSelected
        ? Icons.check
        : Icons.airline_seat_recline_normal;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        selected: isSelected,
        enabled: isAvailable || isSelected,
        child: Opacity(
          opacity: isDisabled ? 0.42 : 1,
          child: InkWell(
            onTap: isAvailable || isSelected ? onTap : null,
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : DetailsColors.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FareBreakdown extends StatelessWidget {
  const _FareBreakdown({required this.viewModel});

  final RideDetailsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Fare Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _FareRow(
            label:
                'Base Fare (x${viewModel.selectedSeatCount == 0 ? 1 : viewModel.selectedSeatCount} seat)',
            value: 'Rs. ${viewModel.baseFare}',
          ),
          const SizedBox(height: 14),
          const Divider(color: DetailsColors.outlineVariant),
          const SizedBox(height: 10),
          _FareRow(
            label: 'Total',
            value: 'Rs. ${viewModel.totalFare}',
            isTotal: true,
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: DetailsColors.surfaceLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info,
                    color: DetailsColors.onSurfaceVariant,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fixed fare. No hidden costs or surge pricing for this route.',
                      style: TextStyle(
                        color: DetailsColors.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingFooter extends StatelessWidget {
  const _BookingFooter({
    required this.viewModel,
    required this.ride,
    required this.onBooked,
  });

  final RideDetailsViewModel viewModel;
  final RideOption ride;
  final VoidCallback onBooked;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DetailsColors.surfaceLowest.withValues(alpha: 0.9),
        border: const Border(
          top: BorderSide(color: DetailsColors.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: viewModel.canConfirm
                ? () async {
                    await viewModel.confirmBooking(ride);
                    if (context.mounted && viewModel.isConfirmed) {
                      onBooked();
                    }
                  }
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: viewModel.isConfirmed
                  ? const Color(0xFF16A34A)
                  : DetailsColors.secondary,
              disabledBackgroundColor: viewModel.isConfirmed
                  ? const Color(0xFF16A34A)
                  : DetailsColors.secondary.withValues(alpha: 0.72),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: viewModel.isProcessing
                  ? Row(
                      key: const ValueKey('processing'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(viewModel.actionLabel),
                      ],
                    )
                  : Row(
                      key: ValueKey(viewModel.actionLabel),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (viewModel.isConfirmed) ...[
                          const Icon(Icons.check_circle),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          viewModel.actionLabel,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!viewModel.isConfirmed) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DetailsColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DetailsColors.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DetailsColors.secondaryFixed,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: DetailsColors.onSecondaryFixed,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DangerBadge extends StatelessWidget {
  const _DangerBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DetailsColors.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: DetailsColors.error,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TierLabel extends StatelessWidget {
  const _TierLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DetailsColors.surfaceLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: DetailsColors.secondary,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              child: SizedBox(width: 4, height: 12),
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DetailsColors.surfaceLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: DetailsColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: DetailsColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
          child: const SizedBox(width: 12, height: 12),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: DetailsColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal
                  ? DetailsColors.primary
                  : DetailsColors.onSurfaceVariant,
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? DetailsColors.secondary : DetailsColors.primary,
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MapPreviewArt extends StatelessWidget {
  const _MapPreviewArt();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapPreviewPainter());
  }
}

class _MapPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = DetailsColors.surfaceHigh,
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFC6C6CD)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x + 40, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 20), gridPaint);
    }

    final routePaint = Paint()
      ..color = DetailsColors.secondary
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final route = Path()
      ..moveTo(size.width * 0.18, size.height * 0.68)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.38,
        size.width * 0.6,
        size.height * 0.8,
        size.width * 0.82,
        size.height * 0.32,
      );
    canvas.drawPath(route, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CarPreviewArt extends StatelessWidget {
  const _CarPreviewArt();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(painter: _CarPreviewPainter()),
    );
  }
}

class _CarPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = DetailsColors.surfaceHigh,
    );
    final car = Paint()..color = Colors.white;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.38,
        size.width * 0.76,
        42,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(rect.shift(const Offset(0, 8)), shadow);
    canvas.drawRRect(rect, car);
    final window = Paint()..color = DetailsColors.secondaryFixed;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.32,
          size.height * 0.28,
          size.width * 0.34,
          24,
        ),
        const Radius.circular(8),
      ),
      window,
    );
    final wheel = Paint()..color = DetailsColors.primary;
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.74), 8, wheel);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.74), 8, wheel);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

abstract final class DetailsColors {
  static const background = Color(0xFFFCF8FA);
  static const surface = Color(0xFFFCF8FA);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F5);
  static const surfaceHigh = Color(0xFFEAE7E9);
  static const primary = Color(0xFF000000);
  static const secondary = Color(0xFF0058BE);
  static const secondaryContainer = Color(0xFF2170E4);
  static const secondaryFixed = Color(0xFFD8E2FF);
  static const onSecondaryFixed = Color(0xFF001A42);
  static const onSurfaceVariant = Color(0xFF45464D);
  static const outlineVariant = Color(0xFFC6C6CD);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
}

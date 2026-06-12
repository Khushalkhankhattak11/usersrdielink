import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/home_content.dart';
import '../../viewmodels/app_theme_view_model.dart';
import '../../viewmodels/home_view_model.dart';

String? _activeRatingDialogRideId;

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onBookSeat,
  });

  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final ValueChanged<RideOption> onBookSeat;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final ratingRide = viewModel.completedRideNeedingRating;
    final ratingRideId = ratingRide?['id']?.toString();
    if (ratingRide != null &&
        ratingRideId != null &&
        _activeRatingDialogRideId != ratingRideId) {
      _activeRatingDialogRideId = ratingRideId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        await _showDriverRatingDialog(context, viewModel, ratingRide);
        _activeRatingDialogRideId = null;
      });
    }

    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopAppBar(
              title:
                  viewModel.selectedTab == HomeTab.home && viewModel.hasSearched
                  ? viewModel.searchTitle
                  : viewModel.appBarTitle,
              subtitle:
                  viewModel.selectedTab == HomeTab.home && viewModel.hasSearched
                  ? viewModel.searchSubtitle
                  : null,
              isSearchResults:
                  viewModel.selectedTab == HomeTab.home &&
                  viewModel.hasSearched,
              hasBackAction:
                  viewModel.selectedTab == HomeTab.wallet &&
                  viewModel.isWalletTopUpOpen,
              onBack:
                  viewModel.selectedTab == HomeTab.wallet &&
                      viewModel.isWalletTopUpOpen
                  ? viewModel.closeWalletTopUp
                  : viewModel.closeSearchResults,
              onLogout: () => _showLogoutDialog(context, onLogout),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 576),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HomeTabContent(
                          viewModel: viewModel,
                          onBookSeat: onBookSeat,
                          onLogout: onLogout,
                          onDeleteAccount: onDeleteAccount,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedTab: viewModel.selectedTab,
        onTabSelected: viewModel.selectTab,
      ),
    );
  }
}

class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent({
    required this.viewModel,
    required this.onBookSeat,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final HomeViewModel viewModel;
  final ValueChanged<RideOption> onBookSeat;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return switch (viewModel.selectedTab) {
      HomeTab.home =>
        viewModel.hasSearched
            ? _SearchResultsContent(
                viewModel: viewModel,
                onBookSeat: onBookSeat,
              )
            : _HomeDashboardContent(
                viewModel: viewModel,
                onBookSeat: onBookSeat,
              ),
      HomeTab.myRides => _MyRidesTab(viewModel: viewModel),
      HomeTab.wallet => _WalletTab(viewModel: viewModel),
      HomeTab.profile => _ProfileTab(
        viewModel: viewModel,
        onLogout: () => _showLogoutDialog(context, onLogout),
        onDeleteAccount: onDeleteAccount,
      ),
    };
  }
}

class _HomeDashboardContent extends StatelessWidget {
  const _HomeDashboardContent({
    required this.viewModel,
    required this.onBookSeat,
  });

  final HomeViewModel viewModel;
  final ValueChanged<RideOption> onBookSeat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchCard(viewModel: viewModel),
        const SizedBox(height: 24),
        _QuickRoutes(
          routes: viewModel.quickRoutes,
          onRouteSelected: viewModel.selectQuickRoute,
        ),
        const SizedBox(height: 24),
        _AvailableRides(viewModel: viewModel, onBookSeat: onBookSeat),
      ],
    );
  }
}

class _SearchResultsContent extends StatelessWidget {
  const _SearchResultsContent({
    required this.viewModel,
    required this.onBookSeat,
  });

  final HomeViewModel viewModel;
  final ValueChanged<RideOption> onBookSeat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchStatsRow(ridesFoundLabel: viewModel.ridesFoundLabel),
        const SizedBox(height: 16),
        if (viewModel.shouldShowRidesSkeleton)
          const _SkeletonList()
        else if (viewModel.rides.isEmpty)
          const _EmptyRideResults()
        else
          ...viewModel.rides.map(
            (ride) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _RideCard(ride: ride, onBookSeat: onBookSeat),
            ),
          ),
      ],
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({
    required this.title,
    required this.onLogout,
    this.subtitle,
    this.isSearchResults = false,
    this.hasBackAction = false,
    this.onBack,
  });

  final String title;
  final VoidCallback onLogout;
  final String? subtitle;
  final bool isSearchResults;
  final bool hasBackAction;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              tooltip: isSearchResults || hasBackAction ? 'Back' : 'Menu',
              onPressed: isSearchResults || hasBackAction ? onBack : () {},
              icon: Icon(
                isSearchResults || hasBackAction
                    ? Icons.arrow_back
                    : Icons.menu,
                color: HomeColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: HomeColors.primary,
                      fontSize: isSearchResults ? 20 : 24,
                      height: isSearchResults ? 28 / 20 : 32 / 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HomeColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            if (isSearchResults)
              IconButton(
                tooltip: 'Filter',
                onPressed: () {},
                icon: const Icon(Icons.filter_list, color: HomeColors.primary),
              )
            else
              PopupMenuButton<String>(
                tooltip: 'Profile',
                onSelected: (value) {
                  if (value == 'logout') {
                    onLogout();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: HomeColors.secondaryFixed,
                  child: Icon(Icons.person, color: HomeColors.secondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _LocationField(
              key: ValueKey('from-${viewModel.from}'),
              icon: Icons.trip_origin,
              iconColor: HomeColors.outline,
              hintText: 'From (e.g., Islamabad)',
              initialValue: viewModel.from,
              readOnly: true,
              onChanged: viewModel.updateFrom,
            ),
            Transform.translate(
              offset: const Offset(0, -2),
              child: IconButton.filled(
                onPressed: viewModel.swapLocations,
                style: IconButton.styleFrom(
                  backgroundColor: HomeColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(34, 34),
                ),
                icon: const Icon(Icons.swap_vert, size: 20),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -4),
              child: _LocationField(
                key: ValueKey('to-${viewModel.to}'),
                icon: Icons.location_on,
                iconColor: HomeColors.secondary,
                hintText: 'To (e.g., Karak)',
                initialValue: viewModel.to,
                onChanged: viewModel.updateTo,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: viewModel.searchRides,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: HomeColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Search Rides',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.hintText,
    this.initialValue = '',
    this.readOnly = false,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String hintText;
  final String initialValue;
  final bool readOnly;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      readOnly: readOnly,
      onTap: readOnly
          ? () => context.read<HomeViewModel>().loadCurrentLocation()
          : null,
      autofocus: false,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => context.read<HomeViewModel>().searchRides(),
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        suffixIcon: readOnly
            ? const Icon(Icons.my_location, color: HomeColors.secondary)
            : null,
        filled: true,
        fillColor: readOnly ? HomeColors.secondaryFixed : HomeColors.surfaceLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _fieldBorder(HomeColors.outlineVariant),
        enabledBorder: _fieldBorder(HomeColors.outlineVariant),
        focusedBorder: _fieldBorder(HomeColors.secondary, width: 2),
      ),
      onChanged: onChanged,
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _QuickRoutes extends StatelessWidget {
  const _QuickRoutes({required this.routes, required this.onRouteSelected});

  final List<QuickRoute> routes;
  final ValueChanged<QuickRoute> onRouteSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionKicker('Quick Routes'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: routes
                .map(
                  (route) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => onRouteSelected(route),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: HomeColors.surfaceHigh,
                        foregroundColor: HomeColors.onSurface,
                        side: const BorderSide(
                          color: HomeColors.outlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        route.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _AvailableRides extends StatelessWidget {
  const _AvailableRides({required this.viewModel, required this.onBookSeat});

  final HomeViewModel viewModel;
  final ValueChanged<RideOption> onBookSeat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                viewModel.searchTitle,
                style: TextStyle(
                  color: HomeColors.primary,
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              viewModel.ridesFoundLabel,
              style: const TextStyle(
                color: HomeColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (viewModel.rides.isEmpty)
          const _EmptyRideResults()
        else
          ...viewModel.rides.map(
            (ride) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _RideCard(ride: ride, onBookSeat: onBookSeat),
            ),
          ),
        _DashboardTiles(viewModel: viewModel),
      ],
    );
  }
}

class _SearchStatsRow extends StatelessWidget {
  const _SearchStatsRow({required this.ridesFoundLabel});

  final String ridesFoundLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          ridesFoundLabel.toUpperCase(),
          style: const TextStyle(
            color: HomeColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        const Icon(Icons.sort, color: HomeColors.secondary, size: 18),
        const SizedBox(width: 4),
        const Text(
          'Cheapest first',
          style: TextStyle(
            color: HomeColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyRideResults extends StatelessWidget {
  const _EmptyRideResults();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.search_off, color: HomeColors.outline, size: 36),
            SizedBox(height: 10),
            Text(
              'No rides found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'Try another destination or use a quick route.',
              textAlign: TextAlign.center,
              style: TextStyle(color: HomeColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride, required this.onBookSeat});

  final RideOption ride;
  final ValueChanged<RideOption> onBookSeat;

  @override
  Widget build(BuildContext context) {
    final isFull =
        ride.availableSeatCount == 0 ||
        ride.seatsLeft.toLowerCase().contains('full');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: ride.accentColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: HomeColors.secondaryFixed,
                              child: Icon(
                                Icons.person,
                                color: HomeColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ride.driverName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 24 / 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    ride.vehicle,
                                    style: const TextStyle(
                                      color: HomeColors.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: ride.badgeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: Text(
                              ride.tier.toUpperCase(),
                              style: TextStyle(
                                color: ride.badgeTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ride.fare,
                        style: const TextStyle(
                          color: HomeColors.primary,
                          fontSize: 24,
                          height: 32 / 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'per seat',
                        style: TextStyle(
                          color: HomeColors.outlineVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const _RouteTimeline(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TimedLocation(time: ride.pickupTime, place: ride.from),
                        const SizedBox(height: 18),
                        _TimedLocation(time: ride.dropoffTime, place: ride.to),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: HomeColors.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ride.vehicleDetails,
                      style: const TextStyle(
                        color: HomeColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: HomeColors.outlineVariant),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event_seat,
                    color: ride.isLowSeat
                        ? HomeColors.error
                        : HomeColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.seatsLeft,
                      style: TextStyle(
                        color: ride.isLowSeat
                            ? HomeColors.error
                            : HomeColors.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: ride.isLowSeat
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: isFull ? null : () => onBookSeat(ride),
                    style: FilledButton.styleFrom(
                      backgroundColor: HomeColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(isFull ? 'Full' : 'Book Seat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimedLocation extends StatelessWidget {
  const _TimedLocation({required this.time, required this.place});

  final String time;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: const TextStyle(
            color: HomeColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          place,
          style: const TextStyle(
            color: HomeColors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: HomeColors.outlineVariant, width: 2),
          ),
        ),
        const SizedBox(
          height: 32,
          child: VerticalDivider(color: HomeColors.outlineVariant, width: 1),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            color: HomeColors.secondary,
            shape: BoxShape.circle,
          ),
          child: SizedBox(width: 10, height: 10),
        ),
      ],
    );
  }
}

class _DashboardTiles extends StatelessWidget {
  const _DashboardTiles({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.schedule,
            label: 'Departing Soon',
            value: viewModel.departingSoonLabel,
            iconColor: HomeColors.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _InfoTile(
            icon: Icons.verified_user,
            label: 'Safety',
            value: viewModel.safetyLabel,
            iconColor: const Color(0xFF98805D),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomeColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 24),
            Text(
              label,
              style: const TextStyle(
                color: HomeColors.outline,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: HomeColors.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRidesTab extends StatelessWidget {
  const _MyRidesTab({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MyRidesSwitcher(
          selectedTab: viewModel.selectedMyRidesTab,
          onTabSelected: viewModel.selectMyRidesTab,
        ),
        const SizedBox(height: 16),
        if (viewModel.shouldShowBookingsSkeleton)
          const _SkeletonList()
        else if (viewModel.selectedMyRidesTab == MyRidesTab.upcoming)
          _UpcomingRidesList(rides: viewModel.upcomingRides)
        else
          _RideHistoryList(rides: viewModel.rideHistory),
      ],
    );
  }
}

class _MyRidesSwitcher extends StatelessWidget {
  const _MyRidesSwitcher({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final MyRidesTab selectedTab;
  final ValueChanged<MyRidesTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: HomeColors.background,
        border: Border(bottom: BorderSide(color: HomeColors.outlineVariant)),
      ),
      child: Row(
        children: [
          _MyRidesTabButton(
            label: 'Upcoming',
            isActive: selectedTab == MyRidesTab.upcoming,
            onTap: () => onTabSelected(MyRidesTab.upcoming),
          ),
          _MyRidesTabButton(
            label: 'Past',
            isActive: selectedTab == MyRidesTab.past,
            onTap: () => onTabSelected(MyRidesTab.past),
          ),
        ],
      ),
    );
  }
}

class _MyRidesTabButton extends StatelessWidget {
  const _MyRidesTabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? HomeColors.primary
                      : HomeColors.onSurfaceVariant,
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isActive ? 44 : 0,
                height: 2,
                color: HomeColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingRidesList extends StatelessWidget {
  const _UpcomingRidesList({required this.rides});

  final List<UpcomingRide> rides;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionKicker('Next Journey'),
        const SizedBox(height: 8),
        if (rides.isEmpty)
          const _EmptyStateCard(
            icon: Icons.event_busy,
            title: 'No current booking is available',
          ),
        ...rides.map(
          (ride) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _UpcomingRideCard(ride: ride),
          ),
        ),
      ],
    );
  }
}

class _UpcomingRideCard extends StatelessWidget {
  const _UpcomingRideCard({required this.ride});

  final UpcomingRide ride;

  @override
  Widget build(BuildContext context) {
    final tierColor = _tierColor(ride.tier);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: _cardDecoration(),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ColoredBox(
                color: tierColor,
                child: const SizedBox(width: 4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatusBadge(
                              label: ride.status,
                              color: HomeColors.secondaryContainer,
                              background: HomeColors.secondaryFixed,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ride.departureTime,
                              style: const TextStyle(
                                color: HomeColors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'SEAT',
                            style: TextStyle(
                              color: HomeColors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            ride.seat,
                            style: const TextStyle(
                              color: HomeColors.onSurface,
                              fontSize: 20,
                              height: 28 / 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _JourneyRoute(
                    origin: ride.origin,
                    destination: ride.destination,
                    accentColor: tierColor,
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: HomeColors.outlineVariant),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: HomeColors.secondaryFixed,
                        child: Icon(Icons.person, color: HomeColors.secondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.driverName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              ride.vehicle,
                              style: const TextStyle(
                                color: HomeColors.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: HomeColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            ride.plateNumber,
                            style: const TextStyle(
                              color: HomeColors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _showManagedRideDialog(context, ride.raw),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: HomeColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideHistoryList extends StatelessWidget {
  const _RideHistoryList({required this.rides});

  final List<RideHistoryItem> rides;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionKicker('History'),
        const SizedBox(height: 8),
        if (rides.isEmpty)
          const _EmptyStateCard(
            icon: Icons.history,
            title: 'No past booking is available',
          ),
        ...rides.map(
          (ride) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RideHistoryCard(ride: ride),
          ),
        ),
      ],
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  const _RideHistoryCard({required this.ride});

  final RideHistoryItem ride;

  @override
  Widget build(BuildContext context) {
    final tierColor = _tierColor(ride.tier);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: _cardDecoration(),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ColoredBox(
                color: tierColor,
                child: const SizedBox(width: 4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _StatusBadge(
                              label: _tierLabel(ride.tier),
                              color: tierColor,
                              background: tierColor.withValues(alpha: 0.14),
                            ),
                            Text(
                              ride.date,
                              style: const TextStyle(
                                color: HomeColors.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              ride.from,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.arrow_forward,
                                color: HomeColors.onSurfaceVariant,
                                size: 16,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                ride.to,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        ride.fare,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ride.status,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _JourneyRoute extends StatelessWidget {
  const _JourneyRoute({
    required this.origin,
    required this.destination,
    required this.accentColor,
  });

  final String origin;
  final String destination;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: HomeColors.surfaceLowest,
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 2),
              ),
            ),
            const SizedBox(
              height: 36,
              child: VerticalDivider(color: HomeColors.outlineVariant),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 16, height: 16),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RidePoint(label: 'ORIGIN', value: origin),
              const SizedBox(height: 16),
              _RidePoint(label: 'DESTINATION', value: destination),
            ],
          ),
        ),
      ],
    );
  }
}

Color _tierColor(RideTier tier) {
  return switch (tier) {
    RideTier.economy => const Color(0xFF22C55E),
    RideTier.standard => const Color(0xFF3B82F6),
    RideTier.premium => const Color(0xFFA855F7),
  };
}

String _tierLabel(RideTier tier) {
  return switch (tier) {
    RideTier.economy => 'Economy',
    RideTier.standard => 'Standard',
    RideTier.premium => 'Premium',
  };
}

String _formatPoints(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index += 1) {
    final remaining = raw.length - index;
    buffer.write(raw[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

class _WalletTab extends StatelessWidget {
  const _WalletTab({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isWalletTopUpOpen) {
      return _WalletTopUpContent(viewModel: viewModel);
    }

    if (viewModel.shouldShowWalletSkeleton) {
      return const _SkeletonList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WalletBalanceCard(
          balance: viewModel.walletBalance,
          onTopUp: viewModel.openWalletTopUp,
        ),
        const SizedBox(height: 16),
        _PendingApprovalsCard(message: viewModel.pendingWalletApprovals),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Transactions',
                style: TextStyle(
                  color: HomeColors.onSurface,
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('SEE ALL')),
          ],
        ),
        const SizedBox(height: 8),
        if (viewModel.walletTransactions.isEmpty)
          const _EmptyStateCard(
            icon: Icons.receipt_long,
            title: 'No recent transaction is available',
          ),
        ...viewModel.walletTransactions.map(
          (transaction) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WalletTransactionTile(transaction: transaction),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Travel Rewards',
          style: TextStyle(
            color: HomeColors.onSurface,
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: viewModel.walletRewards
              .map(
                (reward) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: reward == viewModel.walletRewards.first ? 12 : 0,
                    ),
                    child: _WalletRewardCard(reward: reward),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({required this.balance, required this.onTopUp});

  final int balance;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionKicker('Current Balance', color: Color(0xFFBEC6E0)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPoints(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 40 / 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text(
                    'pts',
                    style: TextStyle(
                      color: Color(0xFFBEC6E0),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onTopUp,
                    icon: const Icon(Icons.add_circle, size: 20),
                    label: const Text('Top Up'),
                    style: FilledButton.styleFrom(
                      backgroundColor: HomeColors.secondaryContainer,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Transfer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletTopUpContent extends StatelessWidget {
  const _WalletTopUpContent({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isWalletProofSubmitted) {
      return _WalletTopUpConfirmation(viewModel: viewModel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Top Up Your Balance',
          style: TextStyle(
            color: HomeColors.primary,
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Follow these simple steps to add credits to your Ride Link wallet via local payment methods.',
          style: TextStyle(
            color: HomeColors.onSurfaceVariant,
            fontSize: 16,
            height: 24 / 16,
          ),
        ),
        const SizedBox(height: 24),
        _PaymentAccountCard(
          method: 'EasyPaisa',
          number: '0300 1234567',
          holder: 'RIDELINK LOGISTICS ADMIN',
          accent: const Color(0xFF37D67A),
          icon: Icons.account_balance_wallet,
          onCopy: () => _copyAccountNumber(context, '03001234567'),
        ),
        const SizedBox(height: 16),
        _PaymentAccountCard(
          method: 'JazzCash',
          number: '0321 7654321',
          holder: 'RIDELINK LOGISTICS ADMIN',
          accent: const Color(0xFFE51D27),
          icon: Icons.payments,
          onCopy: () => _copyAccountNumber(context, '03217654321'),
        ),
        const SizedBox(height: 24),
        const _TopUpInstructionsCard(),
        const SizedBox(height: 24),
        _PaymentProofUploadCard(viewModel: viewModel),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('wallet_submit_verification'),
          onPressed:
              viewModel.hasWalletProof && !viewModel.isSubmittingWalletProof
              ? () async {
                  await viewModel.submitWalletProof();
                }
              : null,
          icon: Icon(
            viewModel.isWalletProofSubmitted
                ? Icons.check_circle
                : viewModel.isSubmittingWalletProof
                ? Icons.sync
                : Icons.verified_user,
          ),
          label: Text(
            viewModel.isWalletProofSubmitted
                ? 'Submitted Successfully'
                : viewModel.isSubmittingWalletProof
                ? 'Uploading...'
                : 'Submit for Verification',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: viewModel.isWalletProofSubmitted
                ? const Color(0xFF059669)
                : HomeColors.secondaryContainer,
            foregroundColor: Colors.white,
            disabledBackgroundColor: HomeColors.secondaryFixed,
            disabledForegroundColor: HomeColors.onSurfaceVariant,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  void _copyAccountNumber(BuildContext context, String number) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Number $number copied!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _WalletTopUpConfirmation extends StatelessWidget {
  const _WalletTopUpConfirmation({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: _cardDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: HomeColors.secondary.withValues(
                        alpha: 0.08,
                      ),
                    ),
                    const CircleAvatar(
                      radius: 46,
                      backgroundColor: HomeColors.secondaryContainer,
                      child: Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Upload Received',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HomeColors.primary,
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We've received your transaction screenshot. Our team is currently verifying the details.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HomeColors.onSurfaceVariant,
                    fontSize: 16,
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 24),
                const _WalletStatusCard(),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(
                      child: _WalletMiniStatusCard(
                        label: 'Expected Credit',
                        value: 'Shortly',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _WalletMiniStatusCard(
                        label: 'Points to Add',
                        value: '1,000 pts',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: HomeColors.secondaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info, color: Color(0xFF001A42), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Once approved, your balance will be updated automatically. You will receive a notification on your device.',
                            style: TextStyle(
                              color: Color(0xFF001A42),
                              fontSize: 14,
                              height: 20 / 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: viewModel.returnToWallet,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Return to Wallet'),
                  style: FilledButton.styleFrom(
                    backgroundColor: HomeColors.secondary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF131B2E)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                '"Dependable transport starts with reliable payments."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 22 / 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletStatusCard extends StatelessWidget {
  const _WalletStatusCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: HomeColors.secondary, width: 4),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionKicker('Status'),
                  SizedBox(height: 4),
                  Text(
                    'Pending Admin Review',
                    style: TextStyle(
                      color: HomeColors.secondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.pending_actions, color: HomeColors.secondary),
          ],
        ),
      ),
    );
  }
}

class _WalletMiniStatusCard extends StatelessWidget {
  const _WalletMiniStatusCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionKicker(label),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: HomeColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentAccountCard extends StatelessWidget {
  const _PaymentAccountCard({
    required this.method,
    required this.number,
    required this.holder,
    required this.accent,
    required this.icon,
    required this.onCopy,
  });

  final String method;
  final String number;
  final String holder;
  final Color accent;
  final IconData icon;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionKicker('Payment Method'),
                      const SizedBox(height: 4),
                      Text(
                        method,
                        style: const TextStyle(
                          color: HomeColors.primary,
                          fontSize: 20,
                          height: 28 / 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: accent,
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionKicker('Account Number'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            number,
                            style: const TextStyle(
                              color: HomeColors.onSurface,
                              fontSize: 16,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.content_copy,
                          color: HomeColors.secondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _SectionKicker('Account Holder'),
            const SizedBox(height: 4),
            Text(
              holder,
              style: const TextStyle(
                color: HomeColors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopUpInstructionsCard extends StatelessWidget {
  const _TopUpInstructionsCard();

  static const _steps = [
    'Copy the account number for your preferred payment method above.',
    'Open your EasyPaisa or JazzCash app and transfer the desired amount.',
    'Take a clear screenshot of the successful transaction confirmation.',
    'Upload the screenshot below. Points will be added after admin verification, usually within 15-30 minutes.',
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: HomeColors.secondary, size: 22),
                SizedBox(width: 8),
                Text(
                  'How to Top Up',
                  style: TextStyle(
                    color: HomeColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < _steps.length; index += 1)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == _steps.length - 1 ? 0 : 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: HomeColors.primary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _steps[index],
                        style: const TextStyle(
                          color: HomeColors.onSurfaceVariant,
                          fontSize: 14,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentProofUploadCard extends StatelessWidget {
  const _PaymentProofUploadCard({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionKicker('Upload Payment Proof'),
        const SizedBox(height: 8),
        InkWell(
          key: const ValueKey('wallet_upload_proof'),
          onTap: viewModel.selectWalletProof,
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: HomeColors.surfaceLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: viewModel.hasWalletProof
                    ? HomeColors.secondary
                    : HomeColors.outlineVariant,
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: HomeColors.surfaceHigh,
                    child: Icon(
                      viewModel.hasWalletProof
                          ? Icons.image
                          : Icons.cloud_upload,
                      color: HomeColors.onSurfaceVariant,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    viewModel.hasWalletProof
                        ? 'payment_screenshot.jpg'
                        : 'Tap to upload screenshot',
                    style: const TextStyle(
                      color: HomeColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    viewModel.hasWalletProof
                        ? 'Ready to submit'
                        : 'JPG, PNG up to 5MB',
                    style: TextStyle(
                      color: viewModel.hasWalletProof
                          ? HomeColors.secondary
                          : HomeColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  if (viewModel.hasWalletProof) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: viewModel.removeWalletProof,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: HomeColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingApprovalsCard extends StatelessWidget {
  const _PendingApprovalsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HomeColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _WalletIconBubble(
              icon: Icons.pending_actions,
              color: HomeColors.secondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Approvals',
                    style: TextStyle(
                      color: HomeColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: HomeColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('View')),
          ],
        ),
      ),
    );
  }
}

class _WalletTransactionTile extends StatelessWidget {
  const _WalletTransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.type == WalletTransactionType.deposit;
    final accent = isDeposit ? HomeColors.secondary : HomeColors.error;
    final amountPrefix = isDeposit ? '+' : '-';
    final amount = transaction.points.abs();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _WalletIconBubble(
              icon: isDeposit ? Icons.account_balance : Icons.directions_bus,
              color: HomeColors.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      color: HomeColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.time,
                    style: const TextStyle(
                      color: HomeColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix ${_formatPoints(amount)} pts',
                  style: TextStyle(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                _SectionKicker(isDeposit ? 'Deposit' : 'Deduction'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletRewardCard extends StatelessWidget {
  const _WalletRewardCard({required this.reward});

  final WalletReward reward;

  @override
  Widget build(BuildContext context) {
    final foreground = reward.isHighlighted
        ? Colors.white
        : HomeColors.onSurface;
    final muted = reward.isHighlighted
        ? Colors.white.withValues(alpha: 0.78)
        : HomeColors.onSurfaceVariant;

    return SizedBox(
      height: 148,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: reward.isHighlighted
              ? HomeColors.secondaryContainer
              : HomeColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                reward.icon,
                color: reward.isHighlighted
                    ? Colors.white
                    : HomeColors.secondary,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward.subtitle,
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletIconBubble extends StatelessWidget {
  const _WalletIconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: HomeColors.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.viewModel,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final HomeViewModel viewModel;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final profile = viewModel.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileIdentityCard(profile: profile),
        const SizedBox(height: 16),
        _ProfileStats(profile: profile),
        const SizedBox(height: 24),
        _PastRidesSection(rides: viewModel.pastRides),
        const SizedBox(height: 24),
        _ThemePreferenceCard(),
        const SizedBox(height: 16),
        _ProfileActions(
          viewModel: viewModel,
          actions: viewModel.profileActions,
          onDeleteAccount: onDeleteAccount,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onLogout,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            foregroundColor: HomeColors.error,
            side: BorderSide(color: HomeColors.error.withValues(alpha: 0.25)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Log Out',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: HomeColors.secondaryContainer,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: HomeColors.secondaryFixed,
                    child: const Icon(
                      Icons.person,
                      color: HomeColors.secondary,
                      size: 52,
                    ),
                  ),
                ),
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: HomeColors.secondaryContainer,
                    child: Icon(Icons.verified, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style: const TextStyle(
                color: HomeColors.onSurface,
                fontSize: 20,
                height: 28 / 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              profile.joined,
              style: const TextStyle(color: HomeColors.onSurfaceVariant),
            ),
            if (profile.email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                profile.email,
                style: const TextStyle(color: HomeColors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: HomeColors.surfaceLow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: HomeColors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(
                      Icons.call,
                      color: HomeColors.secondary,
                      size: 16,
                    ),
                    Text(
                      profile.phone,
                      style: const TextStyle(
                        color: HomeColors.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Verified',
                      style: TextStyle(
                        color: HomeColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      icon: Icons.directions_car,
      iconColor: HomeColors.secondaryContainer,
      value: profile.ridesTaken,
      label: 'Rides Taken',
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: HomeColors.primary,
                fontSize: 24,
                height: 32 / 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HomeColors.onSurfaceVariant,
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastRidesSection extends StatelessWidget {
  const _PastRidesSection({required this.rides});

  final List<PastRide> rides;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Past Rides',
                style: TextStyle(
                  color: HomeColors.onSurface,
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 8),
        if (rides.isEmpty)
          const _EmptyStateCard(
            icon: Icons.history,
            title: 'No past booking is available',
          ),
        ...rides.map(
          (ride) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PastRideCard(ride: ride),
          ),
        ),
      ],
    );
  }
}

class _PastRideCard extends StatelessWidget {
  const _PastRideCard({required this.ride});

  final PastRide ride;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: _cardDecoration(),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ColoredBox(
                color: ride.accentColor,
                child: const SizedBox(width: 4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _RouteTimeline(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RidePoint(label: 'ORIGIN', value: ride.origin),
                            const SizedBox(height: 12),
                            _RidePoint(
                              label: 'DESTINATION',
                              value: ride.destination,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ride.fare,
                            style: const TextStyle(
                              color: HomeColors.primary,
                              fontSize: 20,
                              height: 28 / 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ride.date,
                            style: const TextStyle(
                              color: HomeColors.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: HomeColors.outlineVariant),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.airport_shuttle,
                        color: HomeColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.vehicle,
                          style: const TextStyle(
                            color: HomeColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: HomeColors.surfaceLow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'FIXED FARE',
                            style: TextStyle(
                              color: HomeColors.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RidePoint extends StatelessWidget {
  const _RidePoint({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: HomeColors.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: HomeColors.onSurface,
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({
    required this.viewModel,
    required this.actions,
    required this.onDeleteAccount,
  });

  final HomeViewModel viewModel;
  final List<ProfileActionItem> actions;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: actions
              .map(
                (item) => _ProfileActionRow(
                  item: item,
                  showDivider: item != actions.last,
                  onTap: () => _handleProfileAction(
                    context,
                    viewModel,
                    item.kind,
                    onDeleteAccount,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ThemePreferenceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeViewModel = context.watch<AppThemeViewModel>();

    return DecoratedBox(
      decoration: _cardDecoration(),
      child: SwitchListTile(
        value: themeViewModel.isDarkMode,
        onChanged: themeViewModel.setDarkMode,
        secondary: const CircleAvatar(
          backgroundColor: HomeColors.surfaceLow,
          child: Icon(Icons.dark_mode, color: HomeColors.onSurfaceVariant),
        ),
        title: const Text(
          'Dark Mode',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Switch between light and dark theme.'),
      ),
    );
  }
}

void _handleProfileAction(
  BuildContext context,
  HomeViewModel viewModel,
  ProfileActionKind kind,
  VoidCallback onDeleteAccount,
) {
  switch (kind) {
    case ProfileActionKind.privacyPolicy:
      _showPrivacyPolicy(context);
    case ProfileActionKind.deleteAccount:
      _showDeleteAccountDialog(context, viewModel, onDeleteAccount);
    case ProfileActionKind.savedRoutes:
    case ProfileActionKind.settings:
    case ProfileActionKind.help:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_profileActionLabel(kind)} coming soon')),
      );
  }
}

String _profileActionLabel(ProfileActionKind kind) {
  return switch (kind) {
    ProfileActionKind.savedRoutes => 'Saved Routes',
    ProfileActionKind.settings => 'Settings',
    ProfileActionKind.help => 'Help & Support',
    ProfileActionKind.privacyPolicy => 'Privacy Policy',
    ProfileActionKind.deleteAccount => 'Delete Account',
  };
}

void _showPrivacyPolicy(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Privacy Policy'),
      content: const SingleChildScrollView(
        child: Text(
          'Ride Link uses account details, contact details, ride booking '
          'details, wallet top-up proof, and local preferences to provide '
          'authentication, trip booking, wallet review, support, and app '
          'personalization.\n\n'
          'Ride Link does not request sensitive device permissions such as '
          'camera, location, contacts, microphone, or storage in this build. '
          'Network access is used for Firebase authentication, database, and '
          'related backend services.\n\n'
          'Do not upload payment proof that contains unrelated personal data. '
          'Top-up proof is used only for admin verification. Account deletion '
          'should remove or request deletion of account data from server '
          'systems, and your Play Console Data Safety form and public privacy '
          'policy must match this behavior.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showDeleteAccountDialog(
  BuildContext context,
  HomeViewModel viewModel,
  VoidCallback onDeleteAccount,
) {
  var isDeleting = false;
  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Delete Account?'),
          content: const Text(
            'Yes will delete your Firebase account and your user data. If you '
            'have an active ride, cancel it first.',
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      setState(() => isDeleting = true);
                      try {
                        await viewModel.deleteCurrentAccount();
                        if (context.mounted) Navigator.of(context).pop();
                        onDeleteAccount();
                      } on Object catch (error) {
                        if (!context.mounted) return;
                        setState(() => isDeleting = false);
                        final message =
                            error.toString().contains('active-booking-exists')
                            ? 'Please cancel your active ride before deleting account.'
                            : error.toString().contains('requires-recent-login')
                            ? 'Please login again, then delete your account.'
                            : 'Unable to delete account. Please try again.';
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: HomeColors.error),
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Yes'),
            ),
          ],
        );
      },
    ),
  );
}

void _showLogoutDialog(BuildContext context, VoidCallback onLogout) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout?'),
      content: const Text('Do you want to logout from this account?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('No'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onLogout();
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}

Future<void> _showDriverRatingDialog(
  BuildContext context,
  HomeViewModel viewModel,
  Map<String, dynamic> ride,
) async {
  final managedRideId = ride['id']?.toString() ?? '';
  final driverName = ride['driverName']?.toString() ?? 'driver';
  var selectedRating = 5;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Rate Your Driver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('How was your completed ride with $driverName?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    tooltip: '$value star',
                    onPressed: () => setState(() => selectedRating = value),
                    icon: Icon(
                      value <= selectedRating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFACC15),
                      size: 34,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                viewModel.dismissRatingPrompt();
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: managedRideId.isEmpty
                  ? null
                  : () async {
                      await viewModel.submitDriverRating(
                        managedRideId: managedRideId,
                        rating: selectedRating,
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
              child: const Text('Submit Rating'),
            ),
          ],
        );
      },
    ),
  );
}

void _showManagedRideDialog(
  BuildContext context,
  Map<String, dynamic> managedRide,
) {
  final viewModel = context.read<HomeViewModel>();
  final rideId = managedRide['id']?.toString() ?? '';
  final driverName = managedRide['driverName']?.toString() ?? 'Driver';
  final driverPhone = managedRide['driverPhone']?.toString() ?? '';
  final seats =
      ((managedRide['seatLabels'] as List<dynamic>?) ??
              (managedRide['seats'] as List<dynamic>?) ??
              const [])
          .map((seat) => seat.toString())
          .join(', ');

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Manage Ride', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('$driverName${driverPhone.isEmpty ? '' : ' - $driverPhone'}'),
            if (seats.isNotEmpty) Text('Seats: $seats'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Contact driver: $driverPhone')),
                );
              },
              icon: const Icon(Icons.call),
              label: const Text('Contact Driver'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Seat change is allowed only when the new seat is not booked.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.event_seat),
              label: const Text('Change Seat'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await viewModel.cancelManagedRide(
                  managedRideId: rideId,
                  driverAgreed: false,
                );
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Ride'),
              style: FilledButton.styleFrom(backgroundColor: HomeColors.error),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await viewModel.cancelManagedRide(
                  managedRideId: rideId,
                  driverAgreed: true,
                );
              },
              child: const Text('Driver agreed, cancel without deduction'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: HomeColors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: HomeColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SkeletonBox(height: 148),
        SizedBox(height: 12),
        _SkeletonBox(height: 148),
        SizedBox(height: 12),
        _SkeletonBox(height: 96),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: HomeColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(height: height),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + (_controller.value * 2), 0),
              end: Alignment(0 + (_controller.value * 2), 0),
              colors: const [
                HomeColors.surfaceHigh,
                Color(0xFFE9EDF5),
                HomeColors.surfaceHigh,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({
    required this.item,
    required this.showDivider,
    required this.onTap,
  });

  final ProfileActionItem item;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: item.icon == Icons.map
                ? HomeColors.secondaryFixed
                : HomeColors.surfaceLow,
            child: Icon(
              item.icon,
              color: item.icon == Icons.map
                  ? HomeColors.secondary
                  : HomeColors.onSurfaceVariant,
            ),
          ),
          title: Text(
            item.label,
            style: TextStyle(
              color: item.isDestructive ? HomeColors.error : null,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: HomeColors.outline),
          onTap: onTap,
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: HomeColors.outlineVariant, height: 1),
          ),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedTab, required this.onTabSelected});

  final HomeTab selectedTab;
  final ValueChanged<HomeTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    const navItems = [
      _NavItemData(tab: HomeTab.home, icon: Icons.home, label: 'Home'),
      _NavItemData(
        tab: HomeTab.myRides,
        icon: Icons.directions_car,
        label: 'My Rides',
      ),
      _NavItemData(
        tab: HomeTab.wallet,
        icon: Icons.account_balance_wallet,
        label: 'Wallet',
      ),
      _NavItemData(tab: HomeTab.profile, icon: Icons.person, label: 'Profile'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeColors.surfaceLowest,
        border: const Border(top: BorderSide(color: HomeColors.outlineVariant)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems
                .map(
                  (item) => _NavItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: item.tab == selectedTab,
                    onTap: () => onTabSelected(item.tab),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.tab,
    required this.icon,
    required this.label,
  });

  final HomeTab tab;
  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive
        ? const Color(0xFFFEFCFF)
        : HomeColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isActive ? HomeColors.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 8,
            vertical: 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionKicker extends StatelessWidget {
  const _SectionKicker(this.text, {this.color = HomeColors.onSurfaceVariant});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: HomeColors.surfaceLowest,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: HomeColors.outlineVariant),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

abstract final class HomeColors {
  static const background = Color(0xFFFCF8FA);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF6F3F5);
  static const surfaceHigh = Color(0xFFEAE7E9);
  static const primary = Color(0xFF000000);
  static const secondary = Color(0xFF0058BE);
  static const secondaryContainer = Color(0xFF2170E4);
  static const secondaryFixed = Color(0xFFD8E2FF);
  static const onSurface = Color(0xFF1B1B1D);
  static const onSurfaceVariant = Color(0xFF45464D);
  static const outline = Color(0xFF76777D);
  static const outlineVariant = Color(0xFFC6C6CD);
  static const error = Color(0xFFBA1A1A);
}

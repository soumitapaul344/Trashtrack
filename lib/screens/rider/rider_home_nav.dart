part of 'rider_home.dart';

extension RiderNavSection on _RiderHomeState {
  // ================= BOTTOM NAV =================
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey.shade400,
      type: BottomNavigationBarType.fixed,
      onTap: (index) => _changeIndex(index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: "History",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wallet_outlined),
          activeIcon: Icon(Icons.wallet),
          label: "Earnings",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    );
  }
}

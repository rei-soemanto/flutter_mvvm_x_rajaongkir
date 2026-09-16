import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/domestic/views/domestic_page.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/history/views/history_page.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/international/views/international_page.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/main_shell/view_models/main_shell_view_model.dart';
import 'package:provider/provider.dart';

/// The navigation shell: three pages behind one bottom navigation bar.
///
/// The pages live in an [IndexedStack], so switching tabs keeps each page's
/// state, including a filled in form and a list of results.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MainShellViewModel>();

    return Scaffold(
      body: IndexedStack(
        index: viewModel.currentIndex,
        children: const [DomesticPage(), InternationalPage(), HistoryPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: viewModel.currentIndex,
        onTap: context.read<MainShellViewModel>().selectIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Domestic',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public_outlined),
            activeIcon: Icon(Icons.public),
            label: 'International',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

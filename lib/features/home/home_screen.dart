import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_navigator.dart';
import '../../data/repositories/sofa_repository.dart';
import 'widgets/sofa_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sofas = context.watch<SofaRepository>().all;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName,
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => AppNavigator.openSettings(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppNavigator.openAddSofa(context),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add sofa'),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                '${AppConstants.tagline}.\nPick a sofa to preview it in 3D or in your room.',
                style: TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: sofas.length,
              itemBuilder: (_, i) => SofaCard(
                sofa: sofas[i],
                onTap: () => AppNavigator.openDetail(context, sofas[i].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

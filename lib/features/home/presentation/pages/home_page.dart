import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../domain/entities/category_entity.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/template_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller = Injector.homeController()..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.status) {
          HomeStatus.initial || HomeStatus.loading => const HomeSkeleton(),
          HomeStatus.failure => Center(
            child: Text(_controller.errorMessage ?? 'Error'),
          ),
          HomeStatus.success => RefreshIndicator(
            onRefresh: () => _controller.load(refresh: true),
            child: _HomeList(categories: _controller.categories),
          ),
        },
      ),
    );
  }
}

class _HomeList extends StatelessWidget {
  const _HomeList({required this.categories});
  final List<CategoryEntity> categories;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final category = categories[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: category.templates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, j) =>
                    TemplateCard(template: category.templates[j]),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'models/grid_feature.dart';
import 'widgets/code_snippet_panel.dart';

export 'models/grid_feature.dart';
export 'widgets/code_snippet_panel.dart';
export 'widgets/demo_header.dart';
export 'pages/pages.dart';

void main() {
  runApp(const AppGridShowcaseApp());
}

class AppGridShowcaseApp extends StatelessWidget {
  const AppGridShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppGrid Documentation & Feature Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const ShowcaseHomeScreen(),
    );
  }
}

class ShowcaseHomeScreen extends StatefulWidget {
  const ShowcaseHomeScreen({super.key});

  @override
  State<ShowcaseHomeScreen> createState() => _ShowcaseHomeScreenState();
}

class _ShowcaseHomeScreenState extends State<ShowcaseHomeScreen> {
  GridFeature _selectedFeature = GridFeature.quickstart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AppGrid',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Interactive Documentation & Feature Explorer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        elevation: 1,
      ),
      body: Row(
        children: [
          // 1. Left Sidebar Navigation Menu
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor.withAlpha(60),
                ),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'FEATURES & MODULES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                ),
                for (final feat in GridFeature.values)
                  ListTile(
                    dense: true,
                    selected: _selectedFeature == feat,
                    selectedTileColor:
                        Theme.of(context).colorScheme.primary.withAlpha(30),
                    leading: Icon(
                      feat.icon,
                      color: _selectedFeature == feat
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(
                      feat.title,
                      style: TextStyle(
                        fontWeight: _selectedFeature == feat
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedFeature == feat
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedFeature = feat);
                    },
                  ),
              ],
            ),
          ),

          // 2. Main Content Split View: Live Interactive Demo (Left) + Code Snippet (Right)
          Expanded(
            child: FeatureDetailSplitView(feature: _selectedFeature),
          ),
        ],
      ),
    );
  }
}

class FeatureDetailSplitView extends StatelessWidget {
  final GridFeature feature;

  const FeatureDetailSplitView({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 500;

        final demoWidget = feature.demoWidget;
        final codeSnippetWidget = CodeSnippetPanel(
          title: feature.title,
          code: feature.codeSnippet,
        );

        if (isWide) {
          return Row(
            children: [
              // Live Interactive Demo View
              Expanded(
                flex: 6,
                child: demoWidget,
              ),
              VerticalDivider(
                width: 1,
                color: Theme.of(context).dividerColor.withAlpha(60),
              ),
              // Code Snippet & Documentation Panel
              Expanded(
                flex: 5,
                child: codeSnippetWidget,
              ),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(child: demoWidget),
              const Divider(height: 1),
              Expanded(child: codeSnippetWidget),
            ],
          );
        }
      },
    );
  }
}

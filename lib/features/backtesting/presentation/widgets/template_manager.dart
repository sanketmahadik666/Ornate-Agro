import 'package:flutter/material.dart';

/// Template management component (Req: Template Functionality)
class TemplateManager extends StatelessWidget {
  const TemplateManager({
    super.key,
    this.onTemplateSelected,
    this.onTemplateCreated,
  });

  final ValueChanged<String>? onTemplateSelected;
  final VoidCallback? onTemplateCreated;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Templates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: onTemplateCreated,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Template'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: _templates.length,
                itemBuilder: (context, index) {
                  final template = _templates[index];
                  return _TemplateCard(
                    template: template,
                    onTap: () => onTemplateSelected?.call(template.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<_Template> _templates = [
    _Template(
      id: 'momentum_basic',
      name: 'Momentum Basic',
      description: 'Basic momentum strategy template',
      category: 'Momentum',
    ),
    _Template(
      id: 'mean_revert_basic',
      name: 'Mean Revert Basic',
      description: 'Basic mean reversion strategy template',
      category: 'Mean Reversion',
    ),
    _Template(
      id: 'pairs_trading',
      name: 'Pairs Trading',
      description: 'Pairs trading strategy template',
      category: 'Pairs Trading',
    ),
  ];
}

class _Template {
  const _Template({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final String category;
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onTap,
  });

  final _Template template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template.category,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const Spacer(),
              Text(
                template.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onTap,
                    child: const Text('Use'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.preview, size: 20),
                    onPressed: () {
                      // TODO: Show template preview
                    },
                    tooltip: 'Preview',
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

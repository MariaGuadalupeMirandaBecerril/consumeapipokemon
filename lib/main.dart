import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cargar .env si existe (no requerido para PokeAPI)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.redAccent,
        brightness: Brightness.light,
      ),
      home: const PokemonScreen(),
    );
  }
}

class PokemonScreen extends StatefulWidget {
  const PokemonScreen({super.key});
  @override
  State<PokemonScreen> createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  final ApiService api = ApiService();
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? pokemonData;
  bool isLoading = false;
  String? errorMessage;

  final List<String> suggestions = const [
    'pikachu', 'charizard', 'bulbasaur', 'squirtle', 'mewtwo'
  ];

  Future<void> getPokemon() async {
    FocusScope.of(context).unfocus();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => errorMessage = 'Escribe el nombre o ID del Pokémon.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      pokemonData = null;
    });

    try {
      final data = await api.fetchPokemon(query);
      setState(() => pokemonData = data);
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _useSuggestion(String value) {
    _controller.text = value;
    getPokemon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Finder'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => getPokemon(),
                          decoration: InputDecoration(
                            labelText: 'Pokémon (nombre o ID)',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_controller.text.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Limpiar',
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _controller.clear();
                                        pokemonData = null;
                                        errorMessage = null;
                                      });
                                    },
                                  ),
                                IconButton(
                                  tooltip: 'Buscar',
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: getPokemon,
                                ),
                              ],
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: -8,
                            children: suggestions
                                .map((s) => ActionChip(
                                      label: Text(s),
                                      onPressed: () => _useSuggestion(s),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (errorMessage != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else if (pokemonData == null)
                  const Center(child: Text('Busca un Pokémon para ver detalles.'))
                else
                  _PokemonDetails(data: pokemonData!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PokemonDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PokemonDetails({required this.data});

  Color _typeColor(String t, BuildContext context) {
    switch (t) {
      case 'fire':
        return Colors.deepOrange;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.amber;
      case 'psychic':
        return Colors.pinkAccent;
      case 'ice':
        return Colors.cyan;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.brown;
      case 'fairy':
        return Colors.pink;
      case 'fighting':
        return Colors.redAccent;
      case 'flying':
        return Colors.lightBlue;
      case 'ghost':
        return Colors.deepPurple;
      case 'ground':
        return Colors.orange;
      case 'rock':
        return Colors.grey;
      case 'steel':
        return Colors.blueGrey;
      case 'bug':
        return Colors.lightGreen;
      case 'poison':
        return Colors.purple;
      case 'normal':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final name = _titleCase((data['name'] as String?) ?? 'Desconocido');
    final id = data['id']?.toString() ?? '?';
    final sprite = data['sprites']?['front_default'] as String?;
    final types = (data['types'] as List?)
            ?.map((t) => t['type']?['name'] as String?)
            .whereType<String>()
            .toList() ??
        const <String>[];

    final heightM = (data['height'] is num) ? (data['height'] / 10.0) : null; // decímetros -> m
    final weightKg = (data['weight'] is num) ? (data['weight'] / 10.0) : null; // hectogramos -> kg

    final abilities = (data['abilities'] as List?)
            ?.map((a) => a['ability']?['name'] as String?)
            .whereType<String>()
            .map(_titleCase)
            .toList() ??
        const <String>[];

    final stats = (data['stats'] as List?)
            ?.map((s) => {
                  'name': s['stat']?['name'],
                  'value': s['base_stat'],
                })
            .toList() ??
        const <Map<String, dynamic>>[];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: sprite != null
                      ? Image.network(
                          sprite,
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return SizedBox(
                              width: 96,
                              height: 96,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          (progress.expectedTotalBytes!)
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 96,
                          height: 96,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.catching_pokemon, size: 48),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name  #$id',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: types
                            .map((t) => Chip(
                                  label: Text(_titleCase(t)),
                                  backgroundColor: _typeColor(t, context)
                                      .withAlpha((0.15 * 255).round()),
                                  side: BorderSide(
                                    color: _typeColor(t, context),
                                  ),
                                  labelStyle: TextStyle(
                                    color: _typeColor(t, context),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.height,
                    label: 'Altura',
                    value: heightM != null ? '${heightM.toStringAsFixed(1)} m' : '--',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.monitor_weight,
                    label: 'Peso',
                    value: weightKg != null ? '${weightKg.toStringAsFixed(1)} kg' : '--',
                  ),
                ),
              ],
            ),

            if (abilities.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Habilidades', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: abilities.map((a) => Chip(label: Text(a))).toList(),
              ),
            ],

            if (stats.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Estadísticas base',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...stats.map((s) {
                final name = (s['name'] as String?) ?? '';
                final value = (s['value'] as num?)?.toDouble() ?? 0;
                final pct = (value / 200).clamp(0.0, 1.0); // escala simple 0-200
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          _titleCase(name.replaceAll('-', ' ')),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (pct as num).toDouble(),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 36,
                        child: Text(value.toStringAsFixed(0),
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontFeatures: [])),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = 'pokeapi.co';

  Future<Map<String, dynamic>> fetchPokemon(String nameOrId) async {
    final id = nameOrId.trim().toLowerCase();
    if (id.isEmpty) {
      throw Exception('Ingresa un nombre o ID de Pokémon.');
    }

    final uri = Uri.https(_baseUrl, '/api/v2/pokemon/$id');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('Pokémon no encontrado.');
      } else if (response.statusCode == 429) {
        throw Exception('Límite de peticiones alcanzado (429).');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on http.ClientException catch (_) {
      throw Exception('Error de conexión HTTPS.');
    } on FormatException catch (_) {
      throw Exception('Error al procesar los datos.');
    } on Exception catch (e) {
      throw Exception('Error: $e');
    }
  }
}


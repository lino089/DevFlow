import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:path/path.dart' as p;

class CodeHighlighterHelper {
  CodeHighlighterHelper._();

  static const Map<String, TextStyle> defaultTheme = atomOneDarkTheme;

  /// Mendeteksi bahasa syntax highlighting berdasarkan ekstensi berkas
  static String? detectLanguage(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.dart':
        return 'dart';
      case '.js':
      case '.mjs':
      case '.cjs':
        return 'javascript';
      case '.ts':
      case '.tsx':
        return 'typescript';
      case '.py':
        return 'python';
      case '.java':
        return 'java';
      case '.kt':
      case '.kts':
        return 'kotlin';
      case '.json':
        return 'json';
      case '.yaml':
      case '.yml':
        return 'yaml';
      case '.html':
        return 'html';
      case '.css':
      case '.scss':
        return 'css';
      case '.sql':
        return 'sql';
      case '.xml':
        return 'xml';
      case '.md':
        return 'markdown';
      case '.sh':
      case '.bash':
        return 'bash';
      case '.c':
      case '.h':
      case '.cpp':
        return 'cpp';
      case '.go':
        return 'go';
      case '.rs':
        return 'rust';
      case '.php':
        return 'php';
      case '.rb':
        return 'ruby';
      case '.swift':
        return 'swift';
      default:
        return null;
    }
  }

  /// Memecah seluruh teks kode menjadi List baris yang sudah ditransformasi ke TextSpan
  /// untuk mendukung List Virtualization (ListView.builder) hingga 2.000+ baris lancar 60 FPS
  static List<List<InlineSpan>> parseSourceToLineSpans(
    String source, {
    String? language,
    Map<String, TextStyle> theme = defaultTheme,
    TextStyle? baseStyle,
  }) {
    final normalized = source.replaceAll('\t', '    ').replaceAll('\r\n', '\n');
    final rawLines = normalized.split('\n');

    try {
      final parsedResult = highlight.parse(normalized, language: language);
      final nodes = parsedResult.nodes ?? [];

      final List<List<InlineSpan>> allLines = [];
      List<InlineSpan> currentLine = [];

      void traverse(Node node, TextStyle? inheritedStyle) {
        final nodeStyle = node.className != null ? theme[node.className!] : null;
        final effectiveStyle = inheritedStyle != null
            ? (nodeStyle != null ? inheritedStyle.merge(nodeStyle) : inheritedStyle)
            : nodeStyle;

        if (node.value != null) {
          final parts = node.value!.split('\n');
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].isNotEmpty) {
              currentLine.add(TextSpan(
                text: parts[i],
                style: effectiveStyle,
              ));
            }
            if (i < parts.length - 1) {
              // Menemukan linebreak baru
              allLines.add(List.from(currentLine));
              currentLine.clear();
            }
          }
        } else if (node.children != null) {
          for (final child in node.children!) {
            traverse(child, effectiveStyle);
          }
        }
      }

      for (final node in nodes) {
        traverse(node, null);
      }

      if (currentLine.isNotEmpty || allLines.isEmpty) {
        allLines.add(currentLine);
      }

      // Pastikan jumlah baris sesuai dengan rawLines
      while (allLines.length < rawLines.length) {
        allLines.add([]);
      }

      return allLines;
    } catch (_) {
      // Fallback aman jika parser highlight gagal
      return rawLines
          .map((line) => [
                TextSpan(
                  text: line.isEmpty ? ' ' : line,
                  style: baseStyle,
                ),
              ])
          .toList();
    }
  }
}

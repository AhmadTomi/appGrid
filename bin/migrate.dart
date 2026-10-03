import 'dart:io';

/// Migration tool for consumers of `app_grid` migrating to the unified AppGridStyle architecture.
///
/// Usage:
///   dart run bin/migrate.dart [directory_or_file]
///
/// If no argument is provided, the current directory is scanned recursively.
void main(List<String> args) {
  final targetPath = args.isNotEmpty ? args.first : '.';
  final target = FileSystemEntity.typeSync(targetPath);

  if (target == FileSystemEntityType.notFound) {
    stderr.writeln('Error: Target path "$targetPath" does not exist.');
    exit(1);
  }

  print('=== AppGrid Migration Tool ===');
  print('Scanning target: $targetPath\n');

  final files = <File>[];
  if (target == FileSystemEntityType.file) {
    if (targetPath.endsWith('.dart')) {
      files.add(File(targetPath));
    }
  } else {
    final dir = Directory(targetPath);
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final path = entity.path;
        if (!path.contains('.dart_tool') &&
            !path.contains('.git') &&
            !path.contains(
                '${Platform.pathSeparator}build${Platform.pathSeparator}') &&
            !path.endsWith('migrate.dart')) {
          files.add(entity);
        }
      }
    }
  }

  int modifiedCount = 0;
  for (final file in files) {
    final originalContent = file.readAsStringSync();
    final migratedContent = migrateDartCode(originalContent);

    if (migratedContent != originalContent) {
      file.writeAsStringSync(migratedContent);
      print('  ✓ Migrated: ${file.path}');
      modifiedCount++;
    }
  }

  print('\nMigration completed. $modifiedCount files modified.');
  if (modifiedCount > 0) {
    print(
        'Tip: Run `dart format .` and `dart analyze` to review migrated code.');
  }
}

/// Set of AppGrid parameters that have moved into AppGridStyle.
const Set<String> _styleParameters = {
  'rowHeight',
  'headerHeight',
  'rowTextStyle',
  'cellTextStyle',
  'headerTextStyle',
  'menuTextStyle',
  'footerHeight',
  'footerBackgroundColor',
  'footerTextStyle',
  'selectedRowColor',
  'evenRowColor',
  'oddRowColor',
  'alternateRowColor',
  'headerBackgroundColor',
  'borderColor',
  'gridLineColor',
  'showHorizontalGridLines',
  'showVerticalGridLines',
  'verticalGridLineColor',
  'showHorizontalScrollbar',
  'showVerticalScrollbar',
  'scrollbarVisibility',
  'verticalScrollbarVisibility',
  'horizontalScrollbarVisibility',
  'scrollbarThickness',
  'scrollbarThumbColor',
  'scrollbarTrackColor',
  'columnMenuIcon',
  'columnAscendingIcon',
  'columnDescendingIcon',
  'iconColor',
  'iconSize',
  'showPinIcon',
};

String migrateDartCode(String code) {
  var result = code;

  // 1. Rename AppGridStyleConfig to AppGridStyle
  result = result.replaceAll(RegExp(r'\bAppGridStyleConfig\b'), 'AppGridStyle');

  // 2. Rename .isFrozen to .pin.isPinned
  result = result.replaceAll(RegExp(r'\.isFrozen\b'), '.pin.isPinned');

  // 3. Rename .isHideable to .canHide
  result = result.replaceAll(RegExp(r'\.isHideable\b'), '.canHide');

  // 4. In AppGridStyle constructors/copyWith: rename cellTextStyle -> rowTextStyle, alternateRowColor -> oddRowColor
  result = _migrateAppGridStyleInvocations(result);

  // 5. Migrate AppGrid constructor calls: gather loose styling parameters into style: AppGridStyle(...)
  result = _migrateAppGridInvocations(result);

  return result;
}

String _migrateAppGridStyleInvocations(String code) {
  final pattern = RegExp(r'AppGridStyle\s*(\.copyWith)?\s*\(');
  var startIndex = 0;
  final buffer = StringBuffer();

  while (true) {
    final match = pattern.firstMatch(code.substring(startIndex));
    if (match == null) {
      buffer.write(code.substring(startIndex));
      break;
    }

    final openParenIndex = startIndex + match.end - 1;
    final closeParenIndex = _findMatchingClose(code, openParenIndex, '(', ')');

    if (closeParenIndex == -1) {
      buffer.write(code.substring(startIndex));
      break;
    }

    buffer.write(code.substring(startIndex, openParenIndex + 1));
    var argsContent = code.substring(openParenIndex + 1, closeParenIndex);

    // Replace aliases inside AppGridStyle args
    argsContent = argsContent.replaceAllMapped(
      RegExp(r'\bcellTextStyle\s*:'),
      (_) => 'rowTextStyle:',
    );
    argsContent = argsContent.replaceAllMapped(
      RegExp(r'\balternateRowColor\s*:'),
      (_) => 'oddRowColor:',
    );

    buffer.write(argsContent);
    buffer.write(')');
    startIndex = closeParenIndex + 1;
  }

  return buffer.toString();
}

String _migrateAppGridInvocations(String code) {
  final pattern = RegExp(r'\bAppGrid\b');
  var startIndex = 0;
  final buffer = StringBuffer();

  while (true) {
    final match = pattern.firstMatch(code.substring(startIndex));
    if (match == null) {
      buffer.write(code.substring(startIndex));
      break;
    }

    final matchStart = startIndex + match.start;
    var cursor = matchStart + 'AppGrid'.length;

    // Skip whitespace
    while (cursor < code.length &&
        (code[cursor] == ' ' ||
            code[cursor] == '\t' ||
            code[cursor] == '\n' ||
            code[cursor] == '\r')) {
      cursor++;
    }

    // Check for generic type arguments <...>
    if (cursor < code.length && code[cursor] == '<') {
      final closeAngle = _findMatchingClose(code, cursor, '<', '>');
      if (closeAngle != -1) {
        cursor = closeAngle + 1;
        while (cursor < code.length &&
            (code[cursor] == ' ' ||
                code[cursor] == '\t' ||
                code[cursor] == '\n' ||
                code[cursor] == '\r')) {
          cursor++;
        }
      }
    }

    // Now expect '('
    if (cursor < code.length && code[cursor] == '(') {
      final openParenIndex = cursor;
      final closeParenIndex =
          _findMatchingClose(code, openParenIndex, '(', ')');
      if (closeParenIndex != -1) {
        buffer.write(code.substring(startIndex, matchStart));
        final constructorPrefix =
            code.substring(matchStart, openParenIndex + 1);
        final argsContent = code.substring(openParenIndex + 1, closeParenIndex);

        final transformedArgs = _transformAppGridArgs(argsContent);
        buffer.write(constructorPrefix);
        buffer.write(transformedArgs);
        buffer.write(')');

        startIndex = closeParenIndex + 1;
        continue;
      }
    }

    // If not a constructor call, write through and advance
    buffer.write(code.substring(startIndex, cursor));
    startIndex = cursor;
  }

  return buffer.toString();
}

String _transformAppGridArgs(String argsContent) {
  final args = _splitArguments(argsContent);
  final looseStyleArgs = <String, String>{};
  final remainingArgs = <String>[];
  String? existingStyleArg;

  for (final arg in args) {
    final trimmed = arg.trim();
    if (trimmed.isEmpty) continue;

    final colonIndex = _findTopLevelColon(arg);
    if (colonIndex == -1) {
      remainingArgs.add(arg);
      continue;
    }

    final name = arg.substring(0, colonIndex).trim();
    final value = arg.substring(colonIndex + 1).trim();

    if (name == 'style') {
      existingStyleArg = value;
    } else if (_styleParameters.contains(name)) {
      // Map alias names
      var mappedName = name;
      if (mappedName == 'cellTextStyle') mappedName = 'rowTextStyle';
      if (mappedName == 'alternateRowColor') mappedName = 'oddRowColor';
      looseStyleArgs[mappedName] = value;
    } else {
      remainingArgs.add(arg);
    }
  }

  if (looseStyleArgs.isEmpty) {
    return argsContent;
  }

  // Merge or construct style argument
  String newStyleExpr;
  if (existingStyleArg != null) {
    // If existing style is AppGridStyle(...) or const AppGridStyle(...)
    final match =
        RegExp(r'^(const\s+)?AppGridStyle\s*\(').firstMatch(existingStyleArg);
    if (match != null) {
      final innerOpenParen = existingStyleArg.indexOf('(');
      final innerCloseParen =
          _findMatchingClose(existingStyleArg, innerOpenParen, '(', ')');
      if (innerCloseParen != -1) {
        final innerArgsContent =
            existingStyleArg.substring(innerOpenParen + 1, innerCloseParen);
        final innerArgs = _splitArguments(innerArgsContent);
        final mergedStyleArgs = <String>[];
        final seenKeys = <String>{};

        for (final inner in innerArgs) {
          final cIdx = _findTopLevelColon(inner);
          if (cIdx != -1) {
            final k = inner.substring(0, cIdx).trim();
            if (looseStyleArgs.containsKey(k)) {
              // Loose param overrides existing style property
              mergedStyleArgs.add('$k: ${looseStyleArgs[k]}');
              seenKeys.add(k);
              continue;
            }
          }
          if (inner.trim().isNotEmpty) mergedStyleArgs.add(inner.trim());
        }

        for (final entry in looseStyleArgs.entries) {
          if (!seenKeys.contains(entry.key)) {
            mergedStyleArgs.add('${entry.key}: ${entry.value}');
          }
        }

        newStyleExpr = 'AppGridStyle(${mergedStyleArgs.join(', ')})';
      } else {
        newStyleExpr =
            '$existingStyleArg.copyWith(${looseStyleArgs.entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
      }
    } else {
      newStyleExpr =
          '$existingStyleArg.copyWith(${looseStyleArgs.entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
    }
  } else {
    // Create new AppGridStyle(...)
    final isConst = _canBeConst(looseStyleArgs.values);
    final prefix = isConst ? 'const AppGridStyle(' : 'AppGridStyle(';
    final styleEntries = looseStyleArgs.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(',\n    ');
    newStyleExpr = '$prefix\n    $styleEntries,\n  )';
  }

  remainingArgs.add('style: $newStyleExpr');

  // Format nicely with indentation
  return '\n  ${remainingArgs.map((a) => a.trim()).join(',\n  ')},\n';
}

int _findMatchingClose(
    String text, int openIndex, String openChar, String closeChar) {
  int depth = 0;
  bool inSingleQuote = false;
  bool inDoubleQuote = false;

  for (int i = openIndex; i < text.length; i++) {
    final char = text[i];
    final prev = i > 0 ? text[i - 1] : '';

    if (char == "'" && prev != r'\' && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
      continue;
    }
    if (char == '"' && prev != r'\' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
      continue;
    }
    if (inSingleQuote || inDoubleQuote) continue;

    if (char == openChar) {
      depth++;
    } else if (char == closeChar) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

int _findTopLevelColon(String text) {
  int parenDepth = 0;
  int bracketDepth = 0;
  int braceDepth = 0;
  bool inSingleQuote = false;
  bool inDoubleQuote = false;

  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    final prev = i > 0 ? text[i - 1] : '';

    if (char == "'" && prev != r'\' && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
      continue;
    }
    if (char == '"' && prev != r'\' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
      continue;
    }
    if (inSingleQuote || inDoubleQuote) continue;

    if (char == '(') parenDepth++;
    if (char == ')') parenDepth--;
    if (char == '[') bracketDepth++;
    if (char == ']') bracketDepth--;
    if (char == '{') braceDepth++;
    if (char == '}') braceDepth--;

    if (char == ':' &&
        parenDepth == 0 &&
        bracketDepth == 0 &&
        braceDepth == 0) {
      return i;
    }
  }
  return -1;
}

List<String> _splitArguments(String argsContent) {
  final args = <String>[];
  int parenDepth = 0;
  int bracketDepth = 0;
  int braceDepth = 0;
  bool inSingleQuote = false;
  bool inDoubleQuote = false;
  int argStart = 0;

  for (int i = 0; i < argsContent.length; i++) {
    final char = argsContent[i];
    final prev = i > 0 ? argsContent[i - 1] : '';

    if (char == "'" && prev != r'\' && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
      continue;
    }
    if (char == '"' && prev != r'\' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
      continue;
    }
    if (inSingleQuote || inDoubleQuote) continue;

    if (char == '(') parenDepth++;
    if (char == ')') parenDepth--;
    if (char == '[') bracketDepth++;
    if (char == ']') bracketDepth--;
    if (char == '{') braceDepth++;
    if (char == '}') braceDepth--;

    if (char == ',' &&
        parenDepth == 0 &&
        bracketDepth == 0 &&
        braceDepth == 0) {
      args.add(argsContent.substring(argStart, i).trim());
      argStart = i + 1;
    }
  }

  if (argStart < argsContent.length) {
    final trailing = argsContent.substring(argStart).trim();
    if (trailing.isNotEmpty) {
      args.add(trailing);
    }
  }

  return args;
}

bool _canBeConst(Iterable<String> values) {
  for (final val in values) {
    final v = val.trim();
    if (RegExp(r'^-?[0-9]+(\.[0-9]+)?$').hasMatch(v)) continue;
    if (v == 'true' || v == 'false' || v == 'null') continue;
    if (v.startsWith("'") || v.startsWith('"')) continue;
    if (v.startsWith('const ')) continue;
    if (v.startsWith('TextStyle(') && !v.contains(r'$')) continue;
    if (RegExp(r'^Colors\.[a-zA-Z]+$').hasMatch(v)) continue;
    if (RegExp(r'^AppGridScrollbarVisibility\.[a-zA-Z]+$').hasMatch(v)) {
      continue;
    }
    return false;
  }
  return true;
}

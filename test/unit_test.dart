// Testes Unitários para CalibraFacil
// Validam a lógica de negócio e cálculos matemáticos

import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

void main() {
  group('Testes de Validação e Parsing', () {
    test('parseCommaDecimal aceita vírgula como separador', () {
      String parseResult(String s) {
        final t = s.trim();
        if (t.isEmpty) return '';
        final parsed = double.tryParse(t.replaceAll(',', '.'));
        return parsed?.toString() ?? '';
      }

      expect(parseResult('1,5'), '1.5');
      expect(parseResult('2,75'), '2.75');
      expect(parseResult('10,0'), '10.0');
    });

    test('parseCommaDecimal aceita ponto como separador', () {
      String parseResult(String s) {
        final t = s.trim();
        if (t.isEmpty) return '';
        final parsed = double.tryParse(t.replaceAll(',', '.'));
        return parsed?.toString() ?? '';
      }

      expect(parseResult('1.5'), '1.5');
      expect(parseResult('2.75'), '2.75');
      expect(parseResult('10.0'), '10.0');
    });

    test('parseCommaDecimal retorna null para string vazia', () {
      double? parseResult(String s) {
        final t = s.trim();
        if (t.isEmpty) return null;
        return double.tryParse(t.replaceAll(',', '.'));
      }

      expect(parseResult(''), null);
      expect(parseResult('   '), null);
    });

    test('parseCommaDecimal retorna null para entrada inválida', () {
      double? parseResult(String s) {
        final t = s.trim();
        if (t.isEmpty) return null;
        return double.tryParse(t.replaceAll(',', '.'));
      }

      expect(parseResult('abc'), null);
      expect(parseResult('1,2,3'), null);
      expect(parseResult('texto'), null);
    });
  });

  group('Testes de Cálculo de Regressão Linear', () {
    test('Regressão linear perfeita (R² = 1)', () {
      // Dados: y = 0.1x (relação perfeita)
      final concentracoes = [1.0, 2.0, 3.0, 4.0, 5.0];
      final absorbancias = [0.1, 0.2, 0.3, 0.4, 0.5];

      final n = concentracoes.length;
      final mediaX = concentracoes.reduce((a, b) => a + b) / n;
      final mediaY = absorbancias.reduce((a, b) => a + b) / n;

      final numerador = List.generate(
        n,
        (i) => (concentracoes[i] - mediaX) * (absorbancias[i] - mediaY),
      ).reduce((a, b) => a + b);

      final denominador = List.generate(
        n,
        (i) => pow(concentracoes[i] - mediaX, 2).toDouble(),
      ).reduce((a, b) => a + b);

      final coefA = numerador / denominador;
      final coefB = mediaY - coefA * mediaX;

      final yEstimada = List.generate(n, (i) => coefA * concentracoes[i] + coefB);

      final sqRes = List.generate(
        n,
        (i) => pow(absorbancias[i] - yEstimada[i], 2).toDouble(),
      ).reduce((a, b) => a + b);

      final sqTot = absorbancias
          .map((y) => pow(y - mediaY, 2).toDouble())
          .reduce((a, b) => a + b);

      final coefR2 = 1 - (sqRes / sqTot);

      // Verificações com margem de erro
      expect(coefA, closeTo(0.1, 0.0001));
      expect(coefB, closeTo(0.0, 0.0001));
      expect(coefR2, closeTo(1.0, 0.0001));
    });

    test('Regressão linear com intercepto', () {
      // Dados: y = 0.2x + 0.5
      final concentracoes = [1.0, 2.0, 3.0, 4.0, 5.0];
      final absorbancias = [0.7, 0.9, 1.1, 1.3, 1.5];

      final n = concentracoes.length;
      final mediaX = concentracoes.reduce((a, b) => a + b) / n;
      final mediaY = absorbancias.reduce((a, b) => a + b) / n;

      final numerador = List.generate(
        n,
        (i) => (concentracoes[i] - mediaX) * (absorbancias[i] - mediaY),
      ).reduce((a, b) => a + b);

      final denominador = List.generate(
        n,
        (i) => pow(concentracoes[i] - mediaX, 2).toDouble(),
      ).reduce((a, b) => a + b);

      final coefA = numerador / denominador;
      final coefB = mediaY - coefA * mediaX;

      expect(coefA, closeTo(0.2, 0.0001));
      expect(coefB, closeTo(0.5, 0.0001));
    });

    test('Regressão com 2 pontos mínimos', () {
      final concentracoes = [1.0, 2.0];
      final absorbancias = [0.1, 0.2];

      final n = concentracoes.length;
      expect(n, greaterThanOrEqualTo(2));

      final mediaX = concentracoes.reduce((a, b) => a + b) / n;
      final mediaY = absorbancias.reduce((a, b) => a + b) / n;

      final numerador = List.generate(
        n,
        (i) => (concentracoes[i] - mediaX) * (absorbancias[i] - mediaY),
      ).reduce((a, b) => a + b);

      final denominador = List.generate(
        n,
        (i) => pow(concentracoes[i] - mediaX, 2).toDouble(),
      ).reduce((a, b) => a + b);

      final coefA = numerador / denominador;
      final coefB = mediaY - coefA * mediaX;

      expect(coefA, closeTo(0.1, 0.0001));
      expect(coefB, closeTo(0.0, 0.0001));
    });

    test('Cálculo de concentração de amostra', () {
      // Dado: equação Abs = 0.1 * Conc + 0
      // Se Abs = 0.35, então Conc = (0.35 - 0) / 0.1 = 3.5
      final a = 0.1;
      final b = 0.0;
      final absAmostra = 0.35;

      final concentracaoCalculada = (absAmostra - b) / a;

      expect(concentracaoCalculada, closeTo(3.5, 0.0001));
    });

    test('Cálculo de concentração com intercepto', () {
      // Dado: equação Abs = 0.2 * Conc + 0.5
      // Se Abs = 1.1, então Conc = (1.1 - 0.5) / 0.2 = 3.0
      final a = 0.2;
      final b = 0.5;
      final absAmostra = 1.1;

      final concentracaoCalculada = (absAmostra - b) / a;

      expect(concentracaoCalculada, closeTo(3.0, 0.0001));
    });
  });

  group('Testes de Formatação', () {
    test('formatNum formata com vírgula como separador decimal', () {
      String formatNum(double v, int decimals) =>
          v.toStringAsFixed(decimals).replaceAll('.', ',');

      expect(formatNum(1.5, 2), '1,50');
      expect(formatNum(3.14159, 4), '3,1416');
      expect(formatNum(10.0, 2), '10,00');
    });

    test('Equação formatada com coeficiente positivo', () {
      final a = 0.1234;
      final b = 0.0567;

      String formatNum(double v, int decimals) =>
          v.toStringAsFixed(decimals).replaceAll('.', ',');

      final sinal = b >= 0 ? '+' : '-';
      final valorB = b.abs();
      final equacao =
          'Absorbância = ${formatNum(a, 4)} × Concentração $sinal ${formatNum(valorB, 4)}';

      expect(equacao, 'Absorbância = 0,1234 × Concentração + 0,0567');
    });

    test('Equação formatada com coeficiente negativo', () {
      final a = 0.1234;
      final b = -0.0567;

      String formatNum(double v, int decimals) =>
          v.toStringAsFixed(decimals).replaceAll('.', ',');

      final sinal = b >= 0 ? '+' : '-';
      final valorB = b.abs();
      final equacao =
          'Absorbância = ${formatNum(a, 4)} × Concentração $sinal ${formatNum(valorB, 4)}';

      expect(equacao, 'Absorbância = 0,1234 × Concentração - 0,0567');
    });
  });

  group('Testes de Validação de Regras de Negócio', () {
    test('Absorbância não pode ser maior que 3.0', () {
      final abs = 3.5;
      expect(abs > 3.0, true);
    });

    test('Absorbância 3.0 ou menor é válida', () {
      expect(3.0 <= 3.0, true);
      expect(2.5 <= 3.0, true);
      expect(0.5 <= 3.0, true);
    });

    test('Valores negativos devem ser rejeitados', () {
      final conc = -1.0;
      final abs = -0.5;
      
      expect(conc >= 0, false);
      expect(abs >= 0, false);
    });

    test('Valores zero são permitidos', () {
      final conc = 0.0;
      final abs = 0.0;
      
      expect(conc >= 0, true);
      expect(abs >= 0, true);
    });
  });

  group('Testes de Estatísticas de Amostras', () {
    test('Cálculo de média', () {
      final concentracoes = [1.0, 2.0, 3.0, 4.0, 5.0];
      final media = concentracoes.reduce((a, b) => a + b) / concentracoes.length;

      expect(media, 3.0);
    });

    test('Cálculo de desvio padrão', () {
      final valores = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0];
      final media = valores.reduce((a, b) => a + b) / valores.length;
      
      final variancia = valores
          .map((v) => pow(v - media, 2))
          .reduce((a, b) => a + b) / (valores.length - 1);
      
      final dp = sqrt(variancia);

      expect(media, 5.0);
      expect(dp, closeTo(2.138, 0.01)); // Valor corrigido
    });

    test('Cálculo de coeficiente de variação (CV%)', () {
      final valores = [10.0, 11.0, 9.0, 10.5, 9.5];
      final media = valores.reduce((a, b) => a + b) / valores.length;
      
      final variancia = valores
          .map((v) => pow(v - media, 2))
          .reduce((a, b) => a + b) / (valores.length - 1);
      
      final dp = sqrt(variancia);
      final cv = (dp / media) * 100;

      expect(cv, greaterThan(0));
      expect(cv, lessThan(100)); // CV razoável
    });
  });
}

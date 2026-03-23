import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'homepage.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const CurvaCalibracaoApp());
}

class CurvaCalibracaoApp extends StatelessWidget {
  const CurvaCalibracaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalibraFacil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Colors.green, fontSize: 10),
          labelStyle: const TextStyle(color: Colors.green),
          floatingLabelStyle: const TextStyle(color: Colors.green),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF2E7D32)),
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
        ),
      ),
      home: const SplashPage(),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController concentracaoController = TextEditingController();
  final TextEditingController absorbanciaController = TextEditingController();
  final TextEditingController amostraController = TextEditingController();

  List<double> concentracoes = [];
  List<double> absorbancias = [];
  List<double> amostras = [];

  double? a;
  double? b;
  double? r2;

  // Formatação e parsing com vírgula como separador decimal
  String formatNum(double v, int decimals) => v.toStringAsFixed(decimals).replaceAll('.', ',');
  double? parseCommaDecimal(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    // Aceita vírgula ou ponto como separador decimal, normalizando para ponto
    return double.tryParse(t.replaceAll(',', '.'));
  }

  String equacaoFormatada() {
    if (a == null || b == null) return '';
    final sinal = b! >= 0 ? '+' : '-';
    final valorB = b!.abs();
    return 'Absorbância = ${formatNum(a!, 4)} × Concentração $sinal ${formatNum(valorB, 4)}';
  }

   void reiniciarApp() {
    setState(() {
      concentracoes.clear();
      absorbancias.clear();
      amostras.clear();
      a = null;
      b = null;
      r2 = null;
      concentracaoController.clear();
      absorbanciaController.clear();
      amostraController.clear();
    });
  }

  void adicionarPar() {
    final concText = concentracaoController.text.trim();
    final absText = absorbanciaController.text.trim();
    
    if (concText.isEmpty || absText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha ambos os campos."))
      );
      return;
    }
    
    final conc = parseCommaDecimal(concText);
    final abs = parseCommaDecimal(absText);

    // Regra: campos de absorbância não devem aceitar valores > 3
    if (abs != null && abs > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absorbância não pode ser superior a 3,0.')),
      );
      return;
    }
    
    if (conc != null && abs != null && conc >= 0 && abs >= 0) {
      setState(() {
        concentracoes.add(conc);
        absorbancias.add(abs);
        concentracaoController.clear();
        absorbanciaController.clear();
      });
      
      // Mostra pop-up com tabela dos pontos inseridos
      _mostrarTabelaPontosDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Valores inválidos. Informe números ≥ 0; aceitamos vírgula (,) ou ponto (.) como separador decimal."))
      );
    }
  }

  void adicionarAmostra() {
    final absText = amostraController.text.trim();
    
    if (absText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha o campo de absorbância."))
      );
      return;
    }
    
    final abs = parseCommaDecimal(absText);

    // Regra: campos de absorbância não devem aceitar valores > 3
    if (abs != null && abs > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absorbância não pode ser superior a 3,0.')),
      );
      return;
    }
    
    if (abs != null && abs >= 0) {
      setState(() {
        amostras.add(abs);
        amostraController.clear();
      });
      // Mostra pop-up com resultados das amostras
      _mostrarResultadosAmostrasDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Valor de absorbância inválido. Informe números ≥ 0; aceitamos vírgula (,) ou ponto (.) como separador decimal."))
      );
    }
  }

  void rodarModelo() {
    if (concentracoes.length >= 2) {
      final n = concentracoes.length;
      final mediaX = concentracoes.reduce((a, b) => a + b) / n;
      final mediaY = absorbancias.reduce((a, b) => a + b) / n;

      final numerador = List.generate(n, (i) => (concentracoes[i] - mediaX) * (absorbancias[i] - mediaY)).reduce((a, b) => a + b);
      final denominador = List.generate(n, (i) => pow(concentracoes[i] - mediaX, 2).toDouble()).reduce((a, b) => a + b);

      final coefA = numerador / denominador;
      final coefB = mediaY - coefA * mediaX;

      final yEstimada = List.generate(n, (i) => coefA * concentracoes[i] + coefB);

      final sqRes = List.generate(n, (i) => pow(absorbancias[i] - yEstimada[i], 2).toDouble()).reduce((a, b) => a + b);
      final sqTot = absorbancias.map((y) => pow(y - mediaY, 2).toDouble()).reduce((a, b) => a + b);

      final coefR2 = 1 - (sqRes / sqTot);

      setState(() {
        a = coefA;
        b = coefB;
        r2 = coefR2;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Adicione ao menos dois pares de dados.")));
    }
  }

  // Gera o relatório em PDF da curva de calibração e, opcionalmente,
  // dos resultados da análise das amostras.
  // Pré-requisito: o modelo de regressão deve ter sido calculado (a, b, r2)
  // e é necessário ao menos um par de dados de calibração.
  Future<void> gerarRelatorioPDF() async {
    if (a == null || b == null || concentracoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Execute o modelo primeiro para gerar o relatório."))
      );
      return;
    }

    // Instancia o documento PDF (biblioteca 'pdf')
    final pdf = pw.Document();

      // Carrega as imagens originais dos assets para o cabeçalho
      final logoData = await rootBundle.load('assets/images/logo.png');
      final homeData = await rootBundle.load('assets/images/home.png');
      final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      final homeImage = pw.MemoryImage(homeData.buffer.asUint8List());
    
    // Calcula estatísticas das amostras se houver valores informados.
    // Conversão: conc = (abs - b) / a
    List<double>? concentracoesAmostras;
    double? media, dp, cv;
    
    if (amostras.isNotEmpty) {
      concentracoesAmostras = amostras.map((abs) => (abs - b!) / a!).toList();
      media = concentracoesAmostras.reduce((a, b) => a + b) / concentracoesAmostras.length;
      dp = sqrt(concentracoesAmostras.map((c) => pow(c - media!, 2)).reduce((a, b) => a + b) / (concentracoesAmostras.length - 1));
      cv = (dp / media) * 100;
    }

    // Constrói a página do relatório (A4) com as seções:
    // cabeçalho, equação/ajuste, dados de calibração, resultados da análise e rodapé.
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 40,
                    height: 40,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'Relatório de Análise',
                        style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Container(
                    width: 40,
                    height: 40,
                    child: pw.Image(homeImage, fit: pw.BoxFit.contain),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Equação da reta
              pw.Text(
                'Equação da Curva de Calibração:',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                equacaoFormatada(),
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'R² = ${formatNum(r2!, 4)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 15),
              
              // Dados de calibração
              pw.Text(
                'Dados de Calibração:',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Concentração (U.C.)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Absorbância', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...List.generate(concentracoes.length, (i) => 
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(formatNum(concentracoes[i], 4)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(formatNum(absorbancias[i], 4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              
              // Resultados das amostras (se existirem)
              if (amostras.isNotEmpty) ...[
                pw.Text(
                  'Resultados da análise =',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Absorbância da Amostra', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Concentração Calculada (U.C.)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...List.generate(amostras.length, (i) => 
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(formatNum(amostras[i], 4)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(formatNum(concentracoesAmostras![i], 4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text('Resultados da análise:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('n = ${amostras.length}'),
                pw.Text('Média = ${formatNum(media!, 4)} U.C.'),
                pw.Text('Desvio padrão = ${formatNum(dp!, 4)} U.C.'),
                pw.Text('Coeficiente de variação = ${formatNum(cv!, 2)}%'),
              ],
              
              // Rodapé
              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Desenvolvido por Ronaldo dos Santos Falcão Filho - IFRN', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'relatorio_curva_calibracao.pdf',
    );
  }


  List<FlSpot> getPontos() {
    return List.generate(concentracoes.length, (i) => FlSpot(concentracoes[i], absorbancias[i]));
  }

  List<FlSpot> getLinhaRegressao() {
    if (a == null || b == null || concentracoes.isEmpty) return [];
    final minX = concentracoes.reduce(min);
    final maxX = concentracoes.reduce(max);
    return [
      FlSpot(minX, a! * minX + b!),
      FlSpot(maxX, a! * maxX + b!)
    ];
  }

  Widget construirGrafico() {
    return AspectRatio(
      aspectRatio: 2.0,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 0.8,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 0.8,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    formatNum(value, 1),
                    style: const TextStyle(fontSize: 8, color: Color(0xFF616161)),
                  );
                },
              ),
              axisNameWidget: const Center(
                child: Text(
                  'Concentração (U.C.)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF616161)),
                ),
              ),
              axisNameSize: 20,
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    formatNum(value, 2),
                    style: const TextStyle(fontSize: 8, color: Color(0xFF616161)),
                  );
                },
              ),
              axisNameWidget: const Center(
                child: Text(
                  'Absorbância',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF616161)),
                ),
              ),
              axisNameSize: 20,
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Color(0xFF616161), width: 1),
              bottom: BorderSide(color: Color(0xFF616161), width: 1),
              right: BorderSide(color: Color(0xFF616161), width: 1),
              top: BorderSide(color: Color(0xFF616161), width: 1),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: getPontos(),
              isCurved: false,
              dotData: const FlDotData(show: true),
              color: Colors.blue,
              barWidth: 0,
              isStrokeCapRound: false,
            ),
            LineChartBarData(
              spots: getLinhaRegressao(),
              isCurved: false,
              dotData: const FlDotData(show: false),
              color: Color(0xFF2E7D32),
              barWidth: 2,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        elevation: 8, // Adiciona sombra para trazer para frente
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0), // Padding left e right
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Título à esquerda
              const Text(
                'CalibraFacil',
                style: TextStyle(
                  color: Color(0xFF2E7D32), // Verde escuro
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              // Imagem à direita
              Container(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: const Offset(0, -1), // Reduzido para evitar corte
                  child: Opacity(
                    opacity: 0.85,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      width: 50,
                      height: 50,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            const Text(
              'Inserir dados para a curva de calibração',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 35, 201, 41)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: concentracaoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.green, fontSize: 10),
                    decoration: const InputDecoration(
                      hintText: 'Concentração (U.C.)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: absorbanciaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.green, fontSize: 10),
                    decoration: const InputDecoration(
                      hintText: 'Absorbância',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: adicionarPar, 
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(100, 32),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Adicionar par de dados', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            
            const Text(
              'Absorbâncias das amostras',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 35, 201, 41)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: amostraController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.green, fontSize: 10),
              decoration: const InputDecoration(
                hintText: 'Absorbância da amostra',
              ),
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: adicionarAmostra,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(100, 32),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Adicionar absorbância', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: rodarModelo,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(100, 32),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      backgroundColor: Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Rodar modelo', style: TextStyle(fontWeight: FontWeight.bold))
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: reiniciarApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(100, 32),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Reiniciar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (a != null && b != null) ...[
              const Text(
                'Modelo:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 35, 201, 41),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                equacaoFormatada(),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'R² = ${formatNum(r2!, 4)}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(" "),
              construirGrafico(),
              const SizedBox(height: 6),
              if (amostras.isNotEmpty) calcularResultados(),
            ],
            
            // Rodapé com informações do desenvolvedor
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 6),
            const Center(
              child: Column(
                children: [
                 
                  SizedBox(height: 5),
                  Text(
                    'Desenvolvido por Ronaldo dos Santos Falcão Filho - IFRN',
                    style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 95, 95, 95)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget calcularResultados() {
    final List<double> concentracoesAmostras = amostras.map((abs) => (abs - b!) / a!).toList();
    final media = concentracoesAmostras.reduce((a, b) => a + b) / concentracoesAmostras.length;
    final dp = sqrt(concentracoesAmostras.map((c) => pow(c - media, 2)).reduce((a, b) => a + b) / (concentracoesAmostras.length - 1));
    final cv = (dp / media) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Resultados da análise:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 35, 201, 41)),
        ),
        Text('n = ${amostras.length}'),
        Text('Média = ${formatNum(media, 2)} U.C.'),
        Text('Desvio padrão = ${formatNum(dp, 2)} U.C.'),
        Text('Coeficiente de variação = ${formatNum(cv, 2)}%'),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton.icon(
            onPressed: gerarRelatorioPDF,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Gerar Relatório'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(120, 32),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
            ],
          );
        }

        void _mostrarResultadosAmostrasDialog() {
          final bool temModelo = a != null && b != null;
          final List<double>? concentracoesAmostras = temModelo
              ? amostras.map((abs) => (abs - b!) / a!).toList()
              : null;

          double? media;
          double? dp;
          double? cv;
          if (temModelo && amostras.length >= 2) {
            media = concentracoesAmostras!.reduce((x, y) => x + y) / concentracoesAmostras.length;
            dp = sqrt(concentracoesAmostras
                    .map((c) => pow(c - media!, 2))
                    .reduce((x, y) => x + y) /
                (concentracoesAmostras.length - 1));
            cv = (dp / media) * 100;
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'Resultados da análise',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 35, 201, 41)),
                ),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520, maxHeight: 380),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DataTable(
                          columns: temModelo
                              ? const [
                                  DataColumn(label: Text('Abs')),
                                  DataColumn(label: Text('Conc. (U.C.)')),
                                ]
                              : const [
                                  DataColumn(label: Text('Abs')),
                                ],
                          rows: List.generate(
                            amostras.length,
                            (i) => DataRow(
                              cells: temModelo
                                  ? [
                                      DataCell(Text(formatNum(amostras[i], 4))),
                                      DataCell(Text(formatNum(concentracoesAmostras![i], 4))),
                                    ]
                                  : [
                                      DataCell(Text(formatNum(amostras[i], 4))),
                                    ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (temModelo && amostras.length >= 2) ...[
                          const Text('Resultados da análise:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('n = ${amostras.length}'),
                          Text('Média = ${formatNum(media!, 2)} U.C.'),
                          Text('Desvio padrão = ${formatNum(dp!, 2)} U.C.'),
                          Text('Coeficiente de variação = ${formatNum(cv!, 2)}%'),
                        ] else ...[
                          const Text(
                            'Execute o modelo (a e b) para calcular as concentrações e estatísticas.',
                            style: TextStyle(color: Color.fromARGB(255, 95, 95, 95)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Fechar'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (amostras.isNotEmpty) {
                        setState(() {
                          amostras.removeLast();
                        });
                      }
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Amostra descartada.')),
                      );
                    },
                    child: const Text(
                      'Descartar amostra',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        }

        void _mostrarTabelaPontosDialog() {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'Pontos inseridos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 35, 201, 41)),
                ),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500, maxHeight: 300),
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Conc.')),
                        DataColumn(label: Text('Abs')),
                      ],
                      rows: List.generate(
                        concentracoes.length,
                        (i) => DataRow(
                          cells: [
                            DataCell(Text(formatNum(concentracoes[i], 4))),
                            DataCell(Text(formatNum(absorbancias[i], 4))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Fechar'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (concentracoes.isNotEmpty && absorbancias.isNotEmpty) {
                        setState(() {
                          concentracoes.removeLast();
                          absorbancias.removeLast();
                        });
                      }
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ponto descartado.')),
                      );
                    },
                    child: const Text(
                      'Descartar ponto',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            },
          );
        }
      }
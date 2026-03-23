import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    // Aguarda primeiro frame para garantir que o contexto esteja pronto (especialmente no Web)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Inicia a animação de "explosão"
      _controller.forward();
      // Espera 3s e navega para a página principal
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100, // verde mais suave
      body: SafeArea(
        child: Column(
          children: [
            // Imagem central com efeito (fade-in) e escala proporcional
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 0.5,
                    child: Image.asset(
                      'assets/images/home.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'Imagem não encontrada: assets/images/home.png',
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text(
                  'Desenvolvido por Ronaldo dos Santos Falcão Filho - IFRN',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Efeito simplificado: somente fade-in da imagem central em 200ms

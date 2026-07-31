// SPDX-License-Identifier: GPL-3.0-only

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:veyra_lab/veyra_lab.dart';

final Measure<Vec2> location = Measure<Vec2>('location', encode: (Vec2 value) => value.toJson());
final Measure<Vec2> priorLocation = Measure<Vec2>('prior_location', encode: (Vec2 value) => value.toJson());
final Measure<Vec2> drift = Measure<Vec2>('drift', encode: (Vec2 value) => value.toJson());
final Measure<double> radius = Measure<double>('radius', unit: 'logical-pixels');
final Measure<int> group = Measure<int>('group');

final class TargetInstrument {
  Vec2 position = const Vec2(480, 300);
}

final class ObservatoryModel extends ChangeNotifier {
  ObservatoryModel() {
    space.registerMeasures(<Measure<Object>>[
      location.erased,
      priorLocation.erased,
      drift.erased,
      radius.erased,
      group.erased,
    ]);
    space.installInstrument<TargetInstrument>(target);
    cohort = space.cohort(CohortLens.all(
      <Measure<Object>>[location.erased, priorLocation.erased, drift.erased],
      label: 'mobile-specimens',
    ));
    _installProtocols();
    seed(220);
  }

  final StudySpace space = StudySpace(seed: 7341);
  late final StudyRunner runner = StudyRunner(
    name: 'Attractor Field Stability Study',
    space: space,
    clock: PulseClock(frequency: 60, maximumSteps: 6),
  );
  final TargetInstrument target = TargetInstrument();
  late final Cohort cohort;
  final math.Random visualRandom = math.Random(19);
  int selectedPanel = 0;

  void _installProtocols() {
    runner.addProtocol(Protocol(
      name: 'archive-prior-state',
      phase: ProtocolPhase.preparation,
      run: (ProtocolContext context) {
        for (final Specimen specimen in cohort.members) {
          space.write(specimen, priorLocation, space.require(specimen, location));
        }
      },
    ));
    runner.addProtocol(Protocol(
      name: 'apply-attractor-field',
      phase: ProtocolPhase.intervention,
      after: const <String>{'archive-prior-state'},
      run: (ProtocolContext context) {
        for (final Specimen specimen in cohort.members) {
          final Vec2 p = space.require(specimen, location);
          Vec2 v = space.require(specimen, drift);
          final Vec2 attraction = (target.position - p).normalized() * 34;
          final Vec2 curl = Vec2(-(p.y - 300), p.x - 480).normalized() * 9;
          v = (v + (attraction + curl) * context.deltaSeconds).limited(82);
          Vec2 next = p + v * context.deltaSeconds;
          if (next.x < 8 || next.x > 952) v = Vec2(-v.x, v.y);
          if (next.y < 8 || next.y > 592) v = Vec2(v.x, -v.y);
          next = Vec2(next.x.clamp(8, 952).toDouble(), next.y.clamp(8, 592).toDouble());
          space.write(specimen, drift, v);
          space.write(specimen, location, next);
        }
      },
    ));
    runner.addProtocol(Protocol(
      name: 'record-cohort-observations',
      phase: ProtocolPhase.observation,
      after: const <String>{'apply-attractor-field'},
      run: (ProtocolContext context) {
        if (context.pulse % 30 != 0) return;
        double energy = 0;
        for (final Specimen specimen in cohort.members) {
          energy += space.require(specimen, drift).lengthSquared;
        }
        context.chronicle.observe(
          context.pulse,
          'mean_kinetic_proxy',
          cohort.length == 0 ? 0 : energy / cohort.length,
          protocol: 'record-cohort-observations',
        );
        context.chronicle.observe(
          context.pulse,
          'active_specimens',
          space.specimenCount,
          protocol: 'record-cohort-observations',
        );
      },
    ));
    runner.addHypothesis(Hypothesis(
      name: 'bounded-population',
      question: 'Does the study retain at least one active specimen?',
      evaluate: (StudySpace space, Chronicle chronicle) => HypothesisResult(
        name: 'bounded-population',
        passed: space.specimenCount > 0,
        explanation: space.specimenCount > 0
            ? 'The active cohort remains observable.'
            : 'No specimens remain in the study.',
        evidence: <String, Object?>{'specimen_count': space.specimenCount},
      ),
    ));
  }

  void seed(int count) {
    for (int index = 0; index < count; index += 1) {
      final Vec2 p = Vec2(
        80 + visualRandom.nextDouble() * 800,
        70 + visualRandom.nextDouble() * 460,
      );
      final double angle = visualRandom.nextDouble() * math.pi * 2;
      final Vec2 velocity = Vec2(math.cos(angle), math.sin(angle)) *
          (18 + visualRandom.nextDouble() * 44);
      space.transaction.spawn(<Measurement<Object>>[
        location(p).erased,
        priorLocation(p).erased,
        drift(velocity).erased,
        radius((1.5 + visualRandom.nextDouble() * 3.0)).erased,
        group((index % 4)).erased,
      ]);
    }
    space.commit();
    notifyListeners();
  }

  void advance(double seconds) {
    runner.advance(seconds);
    notifyListeners();
  }

  void setTarget(Offset position) {
    target.position = Vec2(position.dx, position.dy);
  }

  void togglePause() {
    runner.paused = !runner.paused;
    notifyListeners();
  }

  void setPanel(int index) {
    selectedPanel = index;
    notifyListeners();
  }
}

final class VeyraObservatoryApp extends StatelessWidget {
  const VeyraObservatoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VeyraMesh Observatory',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF65D7FF),
        scaffoldBackgroundColor: const Color(0xFF060A12),
        useMaterial3: true,
      ),
      home: const ObservatoryScreen(),
    );
  }
}

final class ObservatoryScreen extends StatefulWidget {
  const ObservatoryScreen({super.key});

  @override
  State<ObservatoryScreen> createState() => _ObservatoryScreenState();
}

final class _ObservatoryScreenState extends State<ObservatoryScreen>
    with SingleTickerProviderStateMixin {
  late final ObservatoryModel model;
  late final Ticker ticker;
  Duration? previous;

  @override
  void initState() {
    super.initState();
    model = ObservatoryModel();
    ticker = createTicker((Duration elapsed) {
      final Duration? before = previous;
      previous = elapsed;
      if (before == null) return;
      final double seconds = (elapsed - before).inMicroseconds / 1000000;
      model.advance(seconds);
    })..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: <Widget>[
                _NavigationRail(model: model),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      _Header(model: model),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: <Widget>[
                              Expanded(flex: 7, child: _FieldPanel(model: model)),
                              const SizedBox(width: 14),
                              Expanded(flex: 3, child: _ResearchPanel(model: model)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _NavigationRail extends StatelessWidget {
  const _NavigationRail({required this.model});
  final ObservatoryModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      decoration: const BoxDecoration(
        color: Color(0xFF0A101C),
        border: Border(right: BorderSide(color: Color(0xFF172234))),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 18),
          const Icon(Icons.hub_outlined, size: 34, color: Color(0xFF65D7FF)),
          const SizedBox(height: 30),
          for (final (int index, IconData icon) in <IconData>[
            Icons.blur_on,
            Icons.account_tree_outlined,
            Icons.timeline,
            Icons.fact_check_outlined,
          ].indexed)
            IconButton.filledTonal(
              onPressed: () => model.setPanel(index),
              isSelected: model.selectedPanel == index,
              icon: Icon(icon),
            ),
          const Spacer(),
          IconButton(onPressed: model.togglePause, icon: Icon(model.runner.paused ? Icons.play_arrow : Icons.pause)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.model});
  final ObservatoryModel model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('VEYRAMESH OBSERVATORY', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                Text('Deterministic simulation research • clean-room comparative analysis', style: TextStyle(color: Color(0xFF8998AF))),
              ],
            ),
          ),
          _Metric(label: 'PULSE', value: '${model.runner.pulse}'),
          _Metric(label: 'SPECIMENS', value: '${model.space.specimenCount}'),
          _Metric(label: 'DROPPED', value: '${model.runner.droppedSeconds.toStringAsFixed(3)}s'),
          const SizedBox(width: 10),
          FilledButton.icon(onPressed: () => model.seed(40), icon: const Icon(Icons.add), label: const Text('Add cohort')),
        ],
      ),
    );
  }
}

final class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF101827), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF73839B), letterSpacing: 1.2)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

final class _FieldPanel extends StatelessWidget {
  const _FieldPanel({required this.model});
  final ObservatoryModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF080E18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1B2A40)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return GestureDetector(
            onPanDown: (DragDownDetails details) => model.setTarget(Offset(
              details.localPosition.dx / constraints.maxWidth * 960,
              details.localPosition.dy / constraints.maxHeight * 600,
            )),
            onPanUpdate: (DragUpdateDetails details) => model.setTarget(Offset(
              details.localPosition.dx / constraints.maxWidth * 960,
              details.localPosition.dy / constraints.maxHeight * 600,
            )),
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _StudyPainter(model),
            ),
          );
        },
      ),
    );
  }
}

final class _StudyPainter extends CustomPainter {
  _StudyPainter(this.model);
  final ObservatoryModel model;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()..color = const Color(0xFF142033)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    final double sx = size.width / 960;
    final double sy = size.height / 600;
    final List<Color> colors = <Color>[
      const Color(0xFF65D7FF),
      const Color(0xFFFF7B9C),
      const Color(0xFFFFD166),
      const Color(0xFF8DEB8D),
    ];
    for (final Specimen specimen in model.cohort.members) {
      final Vec2 previous = model.space.require(specimen, priorLocation);
      final Vec2 current = model.space.require(specimen, location);
      final Vec2 p = previous.lerp(current, model.runner.interpolation);
      final double r = model.space.require(specimen, radius);
      final int g = model.space.require(specimen, group);
      final Paint paint = Paint()..color = colors[g % colors.length].withValues(alpha: 0.82);
      canvas.drawCircle(Offset(p.x * sx, p.y * sy), r, paint);
    }
    final Vec2 t = model.target.position;
    final Offset center = Offset(t.x * sx, t.y * sy);
    final Paint targetPaint = Paint()..color = const Color(0xFFEEF6FF)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawCircle(center, 14, targetPaint);
    canvas.drawLine(center - const Offset(20, 0), center + const Offset(20, 0), targetPaint);
    canvas.drawLine(center - const Offset(0, 20), center + const Offset(0, 20), targetPaint);
  }

  @override
  bool shouldRepaint(covariant _StudyPainter oldDelegate) => true;
}

final class _ResearchPanel extends StatelessWidget {
  const _ResearchPanel({required this.model});
  final ObservatoryModel model;

  @override
  Widget build(BuildContext context) {
    final List<Widget> panels = <Widget>[
      _Overview(model: model),
      _ProtocolView(model: model),
      _TraceView(model: model),
      _IntegrityView(model: model),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B121F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1B2A40)),
      ),
      child: panels[model.selectedPanel],
    );
  }
}

final class _Overview extends StatelessWidget {
  const _Overview({required this.model});
  final ObservatoryModel model;

  @override
  Widget build(BuildContext context) {
    final List<HypothesisResult> results = model.runner.evaluateHypotheses();
    return ListView(children: <Widget>[
      const Text('STUDY OVERVIEW', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      const SizedBox(height: 16),
      _InfoCard(title: 'Purpose', body: 'Measure deterministic field behavior and expose protocol timing. This is a research instrument, not a game engine.'),
      _InfoCard(title: 'Cohort', body: '${model.cohort.length} specimens satisfy the mobile-specimens lens.'),
      _InfoCard(title: 'Reproducibility', body: 'Seed ${model.space.seed}; fixed pulse frequency ${model.runner.clock.frequency.toStringAsFixed(0)} Hz.'),
      for (final HypothesisResult result in results)
        _InfoCard(title: result.passed ? 'Hypothesis passed' : 'Hypothesis failed', body: '${result.name}: ${result.explanation}'),
    ]);
  }
}

final class _ProtocolView extends StatelessWidget {
  const _ProtocolView({required this.model});
  final ObservatoryModel model;

  @override
  Widget build(BuildContext context) {
    return ListView(children: <Widget>[
      const Text('PROTOCOL GRAPH', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      const SizedBox(height: 14),
      for (final Protocol protocol in model.runner.protocols.ordered())
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(radius: 13, child: Text('${ProtocolPhase.values.indexOf(protocol.phase) + 1}')),
          title: Text(protocol.name),
          subtitle: Text(protocol.phase.name),
        ),
    ]);
  }
}

final class _TraceView extends StatelessWidget {
  const _TraceView({required this.model});
  final ObservatoryModel model;

  @override
  Widget build(BuildContext context) {
    final List<Observation> observations = model.runner.chronicle.observations.reversed.take(12).toList();
    return ListView(children: <Widget>[
      const Text('CHRONICLE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      const SizedBox(height: 14),
      if (observations.isEmpty) const Text('Observations appear every 30 pulses.', style: TextStyle(color: Color(0xFF8998AF))),
      for (final Observation observation in observations)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(observation.channel),
          subtitle: Text('pulse ${observation.pulse}'),
          trailing: Text('${observation.value}'),
        ),
    ]);
  }
}

final class _IntegrityView extends StatelessWidget {
  const _IntegrityView({required this.model});
  final ObservatoryModel model;

  @override
  Widget build(BuildContext context) {
    return const ListView(children: <Widget>[
      Text('TRANSFORMATIVE-USE BOUNDARY', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      SizedBox(height: 16),
      _InfoCard(title: 'Independent purpose', body: 'Research, teaching, measurement, criticism, and comparative analysis.'),
      _InfoCard(title: 'No source dependency', body: 'The runtime is independently expressed and does not require third-party implementation source.'),
      _InfoCard(title: 'Reference quarantine', body: 'Optional references are excluded from builds and require a claim manifest.'),
      _InfoCard(title: 'No automatic legal conclusion', body: 'The manifest records contributor reasoning; fair use remains fact-specific.'),
    ]);
  }
}

final class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF111B2B), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(color: Color(0xFF9BA9BC), height: 1.35)),
      ]),
    );
  }
}

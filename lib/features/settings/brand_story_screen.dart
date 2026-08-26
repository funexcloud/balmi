import 'package:flutter/material.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../widgets/balmi_app_bar.dart';
import '../../widgets/balmi_wordmark.dart';

/// Optional brand story — Sweet Potato narrative (not a medical claim).
/// Linked from Settings → About; not part of first-run onboarding.
class BrandStoryScreen extends StatelessWidget {
  const BrandStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: const BalmiAppBar(title: BalmiCopy.brandStoryTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const BalmiWordmark(height: 40),
          const SizedBox(height: 20),
          Text(
            BalmiCopy.brandStoryWhyTitle,
            style: BalmiTheme.body(
              size: 20,
              weight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            BalmiCopy.brandStoryHook,
            style: BalmiTheme.body(
              size: 16,
              weight: FontWeight.w800,
              color: BalmiColors.potato,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          _StoryParagraph(BalmiCopy.brandStoryBody1),
          const SizedBox(height: 14),
          _StoryParagraph(BalmiCopy.brandStoryBody2),
          const SizedBox(height: 14),
          _StoryParagraph(BalmiCopy.brandStoryBody3),
          const SizedBox(height: 28),
          Container(
            height: 3,
            width: 48,
            decoration: BoxDecoration(
              color: BalmiColors.potato,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            BalmiCopy.brandStoryBridge,
            style: BalmiTheme.body(
              size: 16,
              weight: FontWeight.w800,
              color: BalmiColors.potatoDk,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            BalmiCopy.brandStoryCredit,
            style: BalmiTheme.body(
              size: 14,
              weight: FontWeight.w700,
              color: BalmiColors.sub,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            BalmiCopy.brandPhilosophy,
            style: BalmiTheme.body(
              size: 13,
              color: BalmiColors.sub,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryParagraph extends StatelessWidget {
  const _StoryParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: BalmiTheme.body(size: 15, height: 1.55),
    );
  }
}

import 'package:flutter/material.dart';

class CreditCircle extends StatelessWidget{
  final int currentCredits;
  final int totalRequired = 128; //NTHU standard

  const CreditCircle({super.key, required this.currentCredits});

  @override
  Widget build(BuildContext context){
    double progress = currentCredits/totalRequired;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children:[
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              strokeWidth: 12,
              backgroundColor: Colors.grey[200],
              color: Colors.purple[700],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$currentCredits', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'out of 128',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
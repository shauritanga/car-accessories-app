import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewWidget extends StatelessWidget {
  final double rating;
  final String comment;
  final String userName;

  const ReviewWidget({
    super.key,
    required this.rating,
    required this.comment,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                RatingBarIndicator(
                  rating: rating,
                  itemBuilder:
                      (context, _) => Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 20.0,
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(comment),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class Comment {
  final String id;
  final String user;
  final String comment;
  final String thumbnail;
  final String date;
  final double rating;

  Comment({
    required this.id,
    required this.user,
    required this.comment,
    required this.thumbnail,
    required this.date,
    required this.rating,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      id: doc.id,
      user: doc['user'],
      comment: doc['comment'],
      thumbnail: doc['thumbnail'],
      date: doc['date'],
      rating: doc['rating'].toDouble(),
    );
  }
}

class CommentsSection extends StatefulWidget {
  final String restoId;

  const CommentsSection({super.key, required this.restoId});

  @override
  _CommentsSectionState createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  double _currentRating = 3.0;
  final User? user = FirebaseAuth.instance.currentUser ;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<String> _uploadImage(File image) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef =
    FirebaseStorage.instance.ref().child('comments/$fileName');
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _addComment() async {
    String imageUrl = '';
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    } else {
      imageUrl = 'https://placehold.co/150x150'; // Placeholder image URL
    }

    if (_commentController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('resto')
          .doc(widget.restoId)
          .collection('comments')
          .add({
        'user': user?.email ?? 'Anonymous',
        'comment': _commentController.text,
        'thumbnail': imageUrl,
        'date': DateTime.now().toString(),
        'rating': _currentRating,
      });
      _commentController.clear();
      setState(() {
        _currentRating = 3.0;
        _imageFile = null;
      });
    }
  }

  void _updateComment(String commentId, String newComment, double newRating) {
    FirebaseFirestore.instance
        .collection('resto')
        .doc(widget.restoId)
        .collection('comments')
        .doc(commentId)
        .update({
      'comment': newComment,
      'date': DateTime.now().toString(),
      'rating': newRating,
    });
  }

  void _deleteComment(String commentId) {
    FirebaseFirestore.instance
        .collection('resto')
        .doc(widget.restoId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  void _confirmDeleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.blue),),
            ),
            TextButton(
              onPressed: () {
                _deleteComment(commentId);
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.blue),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            labelText: 'Add a comment',
            suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: Colors.black87),
              onPressed: _addComment,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black87),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
          style: const TextStyle(color: Colors.black),
        ),
        const SizedBox(height: 10),
        _imageFile != null
            ? Image.file(_imageFile!)
            : IconButton(
          icon: const Icon(Icons.photo, color: Colors.black87),
          onPressed: _pickImage,
          tooltip: 'Pick Image',
        ),
        RatingBar.builder(
          initialRating: _currentRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (rating) {
            setState(() {
              _currentRating = rating;
            });
          },
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('resto')
              .doc(widget.restoId)
              .collection('comments')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                Comment comment = Comment.fromDocument(doc);
                bool isCurrentUserComment = comment.user == user?.email;
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      comment.user,
                      style: const TextStyle(color: Colors.black),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.comment,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        RatingBarIndicator(
                          rating: comment.rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 20.0,
                          direction: Axis.horizontal,
                        ),
                      ],
                    ),
                    leading: (comment.thumbnail.isNotEmpty && comment.thumbnail != 'NO_IMAGE')
                        ? Image.network(
                      comment.thumbnail,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                      },
                    )
                        : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    trailing: isCurrentUserComment
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black87),
                          onPressed: () {
                            _showEditCommentDialog(comment);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.black87),
                          onPressed: () {
                            _confirmDeleteComment(comment.id);
                          },
                        ),
                      ],
                    )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showEditCommentDialog(Comment comment) {
    TextEditingController editController =
    TextEditingController(text: comment.comment);
    double editRating = comment.rating;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                ),
                style: const TextStyle(color: Colors.black),
              ),
              RatingBar.builder(
                initialRating: editRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  editRating = rating;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                _updateComment(comment.id, editController.text, editRating);
                Navigator.of(context).pop();
              },
              child: const Text('Save', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
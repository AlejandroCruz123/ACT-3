import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facebook Post App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PostPage(),
    );
  }
}

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _subtextController = TextEditingController();
  File? _image;
  List posts = [];

  // Create a logger
  final _logger = Logger('PostPage');

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPost() async {
    if (_image == null || _subtextController.text.isEmpty) {
      _logger.warning('Image or Subtext is missing');
      return;
    }

    final uri = Uri.parse('http://localhost:3000/api/posts');
    final request = http.MultipartRequest('POST', uri);

    final imageFile = await http.MultipartFile.fromPath('image', _image!.path);

    request.files.add(imageFile);
    request.fields['subtext'] = _subtextController.text;

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        _getPosts();
        setState(() {
          _image = null;
          _subtextController.clear();
        });
        _logger.info('Post created successfully');
      } else {
        _logger.severe(
          'Failed to create post. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.severe('Error during post creation: $e');
    }
  }

  Future<void> _getPosts() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/posts'),
      );

      if (response.statusCode == 200) {
        setState(() {
          posts = json.decode(response.body);
        });
      } else {
        _logger.severe(
          'Failed to load posts. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.severe('Error fetching posts: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Facebook Post App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _subtextController,
              decoration: InputDecoration(labelText: 'Subtext'),
            ),
            SizedBox(height: 16),
            _image == null
                ? IconButton(icon: Icon(Icons.image), onPressed: _pickImage)
                : Image.file(_image!),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _createPost, child: Text('Create Post')),
            SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    child: ListTile(
                      leading:
                          post['image'] != null
                              ? Image.network(
                                'http://localhost:3000/uploads/${post['image']}',
                                width: 50,
                                height: 50,
                              )
                              : Icon(Icons.image),
                      title: Text(post['subtext']),
                      subtitle: Text(post['created_at']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

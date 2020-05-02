import 'dart:io';

import 'package:compound/locator.dart';
import 'package:compound/models/cloud_storage_result.dart';
import 'package:compound/models/post.dart';
import 'package:compound/services/cloud_storage_service.dart';
import 'package:compound/services/dialog_service.dart';
import 'package:compound/services/firestore_service.dart';
import 'package:compound/services/navigation_service.dart';
import 'package:compound/utils/image_selector.dart';
import 'package:compound/viewmodels/base_model.dart';
import 'package:flutter/foundation.dart';

class CreatePostViewModel extends BaseModel {
  final FirestoreService _firestoreService = locator<FirestoreService>();
  final DialogService _dialogService = locator<DialogService>();
  final NavigationService _navigationService = locator<NavigationService>();

  final ImageSelector _imageSelector = locator<ImageSelector>();
  final CloudStorageService _cloudStorageService = locator<CloudStorageService>();

  File _selectedImage;
  File get selectedImage => _selectedImage;
  var flag=0;

  Future selectImage() async {
    var tempImage = await _imageSelector.selectImage();
    if(tempImage != null) {
      _selectedImage = tempImage;
      flag=1;
      notifyListeners();
    }
  }

  Post _edittingPost;

  bool get _editting => _edittingPost != null;



  Future addPost({@required String title}) async {
    setBusy(true);

    CloudStorageResult storageResult;
    storageResult=null;
    var result;

    if (!_editting && flag==1) {
      storageResult = await _cloudStorageService.uploadImage(
        imageToUpload: _selectedImage,
        title: title,
      ) ;
      result = await _firestoreService.addPost(Post(
        title: title,
        userId: currentUser.id,
        imageUrl: storageResult.imageUrl,
        imageFileName: storageResult.imageFileName,
      ));
      flag=0;
    }
    else if (!_editting && flag==0 ) {
      result = await _firestoreService.addPost(Post(
        title: title,
        userId: currentUser.id,

      ));
    } else if(_editting && flag==0) {
      result = await _firestoreService.updatePost(Post(
        title: title,
        userId: _edittingPost.userId,
        documentId: _edittingPost.documentId,
        imageUrl: _edittingPost.imageUrl,
        imageFileName: _edittingPost.imageFileName,
      ));
    }
      else if(_editting && flag==1){
      storageResult = await _cloudStorageService.uploadImage(
        imageToUpload: _selectedImage,
        title: title,
      ) ;
      result = await _firestoreService.updatePost(Post(
          title: title,
          userId: _edittingPost.userId,
          documentId: _edittingPost.documentId,
        imageUrl: storageResult.imageUrl,
        imageFileName: storageResult.imageFileName,
      ));
      flag=0;

    }

    setBusy(false);

    if (result is String) {
      await _dialogService.showDialog(
        title: 'Cound not create post',
        description: result,
      );
    } else {
      await _dialogService.showDialog(
        title: 'Post successfully Added',
        description: 'Your post has been created',
      );
    }

    _navigationService.pop();
  }

  void setEdittingPost(Post edittingPost) {
    _edittingPost = edittingPost;
  }
}
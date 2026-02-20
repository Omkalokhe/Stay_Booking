package com.service;

import org.springframework.core.io.Resource;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface RoomPhotoStorageService {
    List<String> saveRoomPhotos(List<MultipartFile> files);

    void deleteRoomPhotos(List<String> photoNames);

    Resource loadRoomPhoto(String filename);

    String toPhotoUrl(String filename);
}

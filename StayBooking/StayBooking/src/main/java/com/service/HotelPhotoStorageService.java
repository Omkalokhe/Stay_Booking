package com.service;

import org.springframework.core.io.Resource;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface HotelPhotoStorageService {
    List<String> saveHotelPhotos(List<MultipartFile> files);

    void deleteHotelPhotos(List<String> photoNames);

    Resource loadHotelPhoto(String filename);

    String toPhotoUrl(String filename);
}

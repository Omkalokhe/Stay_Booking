package com.serviceImpl;

import com.service.HotelPhotoStorageService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class HotelPhotoStorageServiceImpl implements HotelPhotoStorageService {

    private final Path uploadPath;
    private final long maxPhotoSizeBytes;
    private final Set<String> allowedExtensions;
    private final Set<String> allowedMimeTypes;

    public HotelPhotoStorageServiceImpl(
            @Value("${app.hotel.photo.upload-dir:uploads/hotels}") String uploadDir,
            @Value("${app.hotel.photo.max-size-bytes:5242880}") long maxPhotoSizeBytes,
            @Value("${app.hotel.photo.allowed-extensions:jpg,jpeg,png,gif,webp,svg}") String allowedExtensions,
            @Value("${app.hotel.photo.allowed-mime-types:image/jpeg,image/png,image/gif,image/webp,image/svg+xml}") String allowedMimeTypes
    ) {
        this.uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
        this.maxPhotoSizeBytes = maxPhotoSizeBytes;
        this.allowedExtensions = parseCsvToLowerSet(allowedExtensions);
        this.allowedMimeTypes = parseCsvToLowerSet(allowedMimeTypes);
        try {
            Files.createDirectories(this.uploadPath);
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to create hotel photo upload directory", exception);
        }
    }

    @Override
    public List<String> saveHotelPhotos(List<MultipartFile> files) {
        if (files == null || files.isEmpty()) {
            return List.of();
        }

        List<String> savedNames = new ArrayList<>();
        for (MultipartFile file : files) {
            if (file == null || file.isEmpty()) {
                continue;
            }
            validateFile(file);

            String extension = extractExtension(Objects.requireNonNullElse(file.getOriginalFilename(), ""));
            String generatedName = UUID.randomUUID() + extension;
            Path destination = uploadPath.resolve(generatedName).normalize();

            if (!destination.startsWith(uploadPath)) {
                throw new IllegalArgumentException("Invalid photo destination path");
            }

            try {
                Files.copy(file.getInputStream(), destination, StandardCopyOption.REPLACE_EXISTING);
                savedNames.add(generatedName);
            } catch (IOException exception) {
                throw new IllegalStateException("Unable to save hotel photo", exception);
            }
        }

        return savedNames;
    }

    @Override
    public void deleteHotelPhotos(List<String> photoNames) {
        if (photoNames == null || photoNames.isEmpty()) {
            return;
        }

        for (String photoName : photoNames) {
            String safeFilename = normalizeFilename(photoName);
            if (safeFilename == null) {
                continue;
            }
            Path target = uploadPath.resolve(safeFilename).normalize();
            if (!target.startsWith(uploadPath)) {
                continue;
            }
            try {
                Files.deleteIfExists(target);
            } catch (IOException ignored) {
                // Intentionally ignored to avoid failing delete/update operations for non-critical file cleanup.
            }
        }
    }

    @Override
    public Resource loadHotelPhoto(String filename) {
        String safeFilename = normalizeFilename(filename);
        if (safeFilename == null) {
            throw new IllegalArgumentException("Photo filename is required");
        }

        Path target = uploadPath.resolve(safeFilename).normalize();
        if (!target.startsWith(uploadPath)) {
            throw new IllegalArgumentException("Invalid photo filename");
        }

        try {
            Resource resource = new UrlResource(target.toUri());
            if (!resource.exists() || !resource.isReadable()) {
                throw new IllegalArgumentException("Photo not found");
            }
            return resource;
        } catch (MalformedURLException exception) {
            throw new IllegalArgumentException("Invalid photo filename", exception);
        }
    }

    @Override
    public String toPhotoUrl(String filename) {
        String safeFilename = normalizeFilename(filename);
        if (safeFilename == null) {
            return "";
        }
        return "/api/hotels/photos/" + safeFilename;
    }

    private void validateFile(MultipartFile file) {
        if (file.getSize() > maxPhotoSizeBytes) {
            throw new IllegalArgumentException("Photo size exceeds allowed limit");
        }

        String originalFilename = Objects.requireNonNullElse(file.getOriginalFilename(), "");
        String extension = extractExtensionWithoutDot(originalFilename);
        String mimeType = Objects.requireNonNullElse(file.getContentType(), "").toLowerCase();

        boolean extensionAllowed = allowedExtensions.contains(extension);
        boolean mimeAllowed = allowedMimeTypes.contains(mimeType);

        if (!(extensionAllowed || mimeAllowed)) {
            throw new IllegalArgumentException("Only image files are allowed (jpg, jpeg, png, gif, webp, svg)");
        }
    }

    private String extractExtension(String originalFilename) {
        int lastDot = originalFilename.lastIndexOf('.');
        if (lastDot < 0 || lastDot == originalFilename.length() - 1) {
            return ".jpg";
        }

        String extension = originalFilename.substring(lastDot).toLowerCase();
        if (!extension.matches("\\.[a-z0-9]{2,5}")) {
            return ".jpg";
        }
        return extension;
    }

    private String extractExtensionWithoutDot(String originalFilename) {
        int lastDot = originalFilename.lastIndexOf('.');
        if (lastDot < 0 || lastDot == originalFilename.length() - 1) {
            return "";
        }
        return originalFilename.substring(lastDot + 1).toLowerCase();
    }

    private Set<String> parseCsvToLowerSet(String csv) {
        if (csv == null || csv.trim().isEmpty()) {
            return new HashSet<>();
        }
        return Arrays.stream(csv.split(","))
                .map(String::trim)
                .map(String::toLowerCase)
                .filter(value -> !value.isEmpty())
                .collect(Collectors.toSet());
    }

    private String normalizeFilename(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }

        String decoded = URLDecoder.decode(value.trim(), StandardCharsets.UTF_8);
        String normalizedSlashes = decoded.replace("\\", "/");

        int lastSlash = normalizedSlashes.lastIndexOf('/');
        String filenameOnly = lastSlash >= 0 ? normalizedSlashes.substring(lastSlash + 1) : normalizedSlashes;

        if (filenameOnly.isBlank() || filenameOnly.contains("..")) {
            return null;
        }

        return filenameOnly;
    }
}

<?php

namespace App\Traits;

use Illuminate\Http\UploadedFile;
use Cloudinary\Configuration\Configuration;
use Cloudinary\Api\Upload\UploadApi;

trait UploadsToCloudinary
{
    /**
     * Upload an image to Cloudinary and return the secure URL.
     *
     * @param UploadedFile $file
     * @param string $folder
     * @return string
     */
    public function uploadToCloudinary(UploadedFile $file, $folder = 'siam')
    {
        $this->configureCloudinary();

        $response = (new UploadApi())->upload($file->getRealPath(), [
            'folder' => $folder
        ]);

        return $response['secure_url'];
    }

    /**
     * Delete an image from Cloudinary by its URL.
     * Extracts the public ID from the URL and calls the Cloudinary API.
     *
     * @param string|null $url
     */
    public function deleteFromCloudinary($url)
    {
        if (!$url) return;

        // Extracts public ID from URL: e.g. https://res.cloudinary.com/.../upload/v12345/folder/file.jpg -> folder/file
        if (preg_match('/upload\/(?:v\d+\/)?([^\.]+)/', $url, $matches)) {
            $publicId = $matches[1];
            
            try {
                $this->configureCloudinary();
                (new UploadApi())->destroy($publicId);
            } catch (\Exception $e) {
                // Ignore deletion errors or log them if a logger is available
                \Illuminate\Support\Facades\Log::warning("Failed to delete Cloudinary image: " . $e->getMessage());
            }
        }
    }

    private function configureCloudinary()
    {
        Configuration::instance([
            'cloud' => [
                'cloud_name' => env('CLOUDINARY_CLOUD_NAME'),
                'api_key'    => env('CLOUDINARY_API_KEY'),
                'api_secret' => env('CLOUDINARY_API_SECRET')
            ],
            'url' => [
                'secure' => true
            ]
        ]);
    }
}

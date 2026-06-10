<?php

namespace App\Traits;

trait HasCloudinaryImage
{
    use UploadsToCloudinary;

    public static function bootHasCloudinaryImage()
    {
        static::updating(function ($model) {
            $field = $model->cloudinaryField ?? 'image_url';
            if ($model->isDirty($field)) {
                $oldImage = $model->getOriginal($field);
                if ($oldImage) {
                    $model->deleteFromCloudinary($oldImage);
                }
            }
        });

        static::deleting(function ($model) {
            $usesSoftDeletes = in_array('Illuminate\Database\Eloquent\SoftDeletes', class_uses_recursive(static::class));
            
            if ($usesSoftDeletes && !$model->isForceDeleting()) {
                return;
            }

            $field = $model->cloudinaryField ?? 'image_url';
            if ($model->{$field}) {
                $model->deleteFromCloudinary($model->{$field});
            }
        });
    }
}

<?php

declare(strict_types=1);

/**
 * Starter Theme functions.
 */

add_action('after_setup_theme', static function (): void {
    add_theme_support('title-tag');
    add_theme_support('post-thumbnails');
});

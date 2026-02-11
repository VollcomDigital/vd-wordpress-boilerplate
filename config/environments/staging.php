<?php

/**
 * Configuration overrides for WP_ENV === 'staging'
 */

use Roots\WPConfig\Config;

/**
 * Keep staging as close to production as possible.
 *
 * You can override production configuration values with `Config::define`.
 */

Config::define('DISALLOW_INDEXING', true);


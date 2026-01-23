<?php

// Simple as the filename is
// Make a tree

function tree(string $path, array $excludeList = []): array
{
    if (in_array($path, $excludeList)) {
        return [];
    }

    if (is_file($path)) {
        return [$path];
    }

    if (!is_dir($path)) {
        return [];
    }

    $slash = '/';

    if ($path === '/') {
        $slash = '';
    } elseif (substr($path, -1, 1) === '/') {
        $path = substr($path, 0, -1);
    }

    if (!is_readable($path)) {
        return [];
    }

    $scan = scandir($path);
    $tree = [];

    foreach ($scan as $value) {
        if ($value === '.' || $value === '..') {
            continue;
        }

        $itempath = $path.$slash.$value;

        foreach ($excludeList as $excluded) {
            if (substr($itempath, 0, strlen($excluded)) === $excluded) {
                continue 2;
            }
        }

        foreach (tree($itempath, $excludeList) as $subitem) {
            $tree[] = $subitem;
        }
    }

    return $tree;
}

$path = $argv[1] ?? null;
$excludeList = $argv[2] ?? null;

if (empty($path)) {
    exit('Empty path');
}

if (!file_exists($path)) {
    exit('Invalid path');
}

if (empty($excludeList)) {
    $excludeList = [];
} else {
    $excludeList = explode(',', $excludeList);
}

$tree = tree($path, $excludeList);

foreach ($tree as $filepath) {
    echo $filepath.PHP_EOL;
}

<?php

/**
 * @file
 * Defines the OpenY Profile install screen by modifying the install form.
 */

use Drupal\openy\Form\ContentSelectForm;
use Drupal\openy\Form\ThirdPartyServicesForm;

/**
 * Implements hook_install_tasks().
 */
function openy_install_tasks() {
  return [
    'openy_select_content' => [
      'display_name' => t('Import demo content'),
      'display' => TRUE,
      'type' => 'form',
      'function' => ContentSelectForm::class,
    ],
    'openy_import_content' => [
      'type' => 'batch',
    ],
    'openy_third_party_services' => [
      'display_name' => t('3rd party services'),
      'display' => TRUE,
      'type' => 'form',
      'function' => ThirdPartyServicesForm::class,
    ],
  ];
}

/**
 * Create batch for content import.
 *
 * @param array $install_state
 *   Installation parameters.
 *
 * @return array
 *   Batch.
 */
function openy_import_content(array &$install_state) {
  $batch = [];

  // @todo Fix block migrations and then add them here.
  // Required migrations. Will be imported anyway.
  $required = [];

  // Optional. Will be imported only if some content will be selected for import.
  $optional = [
    'openy_demo_taxonomy_term_facility_type',
    'openy_demo_block_content_footer',
  ];

  // Maps selection to migrations.
  $map = [
    'branches' => [
      'openy_demo_node_branch'
    ],
    'blog' => [
      'openy_demo_node_blog',
    ],
    'landing' => [
      'openy_demo_node_landing',
    ],
    'programs' => [
      'openy_demo_node_program',
      'openy_demo_node_program_subcategory',
    ],
    'home_alt' => [
      'openy_demo_node_home_alt_landing',
    ],
    'menus' => [
      'openy_demo_menu_link_main',
      'openy_demo_menu_link_footer',
    ],
  ];

  // Add home_alt if landing is not included.
  if (!in_array('landing', $install_state['openy']['content'])) {
    $install_state['openy']['content'][] = 'home_alt';
  }

  // Run required migrations.
  foreach ($required as $migration) {
    $batch['operations'][] = ['openy_import_migration', (array) $migration];
  }

  // Run optional migrations.
  if (!empty($install_state['openy']['content'])) {
    foreach ($optional as $migration) {
      $batch['operations'][] = ['openy_import_migration', (array) $migration];
    }
  }

  // Run migrations for selected content.
  foreach ($install_state['openy']['content'] as $content) {
    foreach ($map[$content] as $migration) {
      $batch['operations'][] = ['openy_import_migration', (array) $migration];
    }
  }

  return $batch;
}

/**
 * Import single migration (with dependencies).
 *
 * @param string $migration_id
 *   Migration ID.
 */
function openy_import_migration($migration_id) {
  $importer = \Drupal::service('openy_migrate.importer');
  $importer->import($migration_id);
}

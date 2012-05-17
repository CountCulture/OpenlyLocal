# ************************************************************
# Sequel Pro SQL dump
# Version 3408
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: localhost (MySQL 5.1.45)
# Database: openlylocal_development
# Generation Time: 2012-05-17 17:27:17 +0100
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table account_lines
# ------------------------------------------------------------

DROP TABLE IF EXISTS `account_lines`;

CREATE TABLE `account_lines` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` int(11) DEFAULT NULL,
  `period` varchar(255) DEFAULT NULL,
  `sub_heading` varchar(255) DEFAULT NULL,
  `classification_id` int(11) DEFAULT NULL,
  `organisation_type` varchar(255) DEFAULT NULL,
  `organisation_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table addresses
# ------------------------------------------------------------

DROP TABLE IF EXISTS `addresses`;

CREATE TABLE `addresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `street_address` mediumtext,
  `locality` varchar(255) DEFAULT NULL,
  `postal_code` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `addressee_type` varchar(255) DEFAULT NULL,
  `addressee_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `region` varchar(255) DEFAULT NULL,
  `former` tinyint(1) DEFAULT '0',
  `lat` double DEFAULT NULL,
  `lng` double DEFAULT NULL,
  `raw_address` text,
  PRIMARY KEY (`id`),
  KEY `index_addresses_on_addressee_id_and_addressee_type` (`addressee_id`,`addressee_type`),
  KEY `index_addresses_on_lat_and_lng` (`lat`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table alert_subscribers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `alert_subscribers`;

CREATE TABLE `alert_subscribers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(128) DEFAULT NULL,
  `postcode_text` varchar(8) DEFAULT NULL,
  `last_sent` datetime DEFAULT NULL,
  `confirmed` tinyint(1) DEFAULT NULL,
  `confirmation_code` varchar(255) DEFAULT NULL,
  `distance` float DEFAULT NULL,
  `bottom_left_lat` float DEFAULT NULL,
  `bottom_left_lng` float DEFAULT NULL,
  `top_right_lat` float DEFAULT NULL,
  `top_right_lng` float DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `postcode_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_alert_subscribers_on_email` (`email`),
  KEY `index_alert_subscribers_on_created_at` (`created_at`),
  KEY `bounding_box_index` (`bottom_left_lat`,`top_right_lat`,`bottom_left_lng`,`top_right_lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table authority
# ------------------------------------------------------------

DROP TABLE IF EXISTS `authority`;

CREATE TABLE `authority` (
  `authority_id` int(11) NOT NULL AUTO_INCREMENT,
  `full_name` varchar(200) NOT NULL,
  `short_name` varchar(100) NOT NULL,
  `planning_email` varchar(100) NOT NULL,
  `feed_url` varchar(255) DEFAULT NULL,
  `external` tinyint(1) DEFAULT NULL,
  `disabled` tinyint(1) DEFAULT NULL,
  `notes` text,
  PRIMARY KEY (`authority_id`),
  KEY `short_name` (`short_name`),
  KEY `search` (`short_name`,`authority_id`,`full_name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table boundaries
# ------------------------------------------------------------

DROP TABLE IF EXISTS `boundaries`;

CREATE TABLE `boundaries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `area_type` varchar(255) DEFAULT NULL,
  `area_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `boundary_line` multipolygon DEFAULT NULL,
  `hectares` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_boundaries_on_area_id_and_area_type` (`area_id`,`area_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table candidates
# ------------------------------------------------------------

DROP TABLE IF EXISTS `candidates`;

CREATE TABLE `candidates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `poll_id` int(11) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `party` varchar(255) DEFAULT NULL,
  `elected` tinyint(1) DEFAULT NULL,
  `votes` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `basic_address` mediumtext,
  `political_party_id` int(11) DEFAULT NULL,
  `member_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_candidates_on_poll_id` (`poll_id`),
  KEY `index_candidates_on_political_party_id` (`political_party_id`),
  KEY `index_candidates_on_member_id` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table charities
# ------------------------------------------------------------

DROP TABLE IF EXISTS `charities`;

CREATE TABLE `charities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `activities` mediumtext,
  `charity_number` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `telephone` varchar(255) DEFAULT NULL,
  `date_registered` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `vat_number` varchar(255) DEFAULT NULL,
  `contact_name` varchar(255) DEFAULT NULL,
  `accounts_date` date DEFAULT NULL,
  `spending` int(11) DEFAULT NULL,
  `income` int(11) DEFAULT NULL,
  `date_removed` date DEFAULT NULL,
  `normalised_title` varchar(255) DEFAULT NULL,
  `employees` int(11) DEFAULT NULL,
  `accounts` mediumtext,
  `financial_breakdown` mediumtext,
  `trustees` mediumtext,
  `other_names` text,
  `volunteers` int(11) DEFAULT NULL,
  `last_checked` datetime DEFAULT NULL,
  `facebook_account_name` varchar(255) DEFAULT NULL,
  `youtube_account_name` varchar(255) DEFAULT NULL,
  `feed_url` varchar(255) DEFAULT NULL,
  `governing_document` mediumtext,
  `company_number` varchar(255) DEFAULT NULL,
  `housing_association_number` varchar(255) DEFAULT NULL,
  `fax` varchar(255) DEFAULT NULL,
  `subsidiary_number` int(11) DEFAULT NULL,
  `area_of_benefit` varchar(255) DEFAULT NULL,
  `signed_up_for_1010` tinyint(1) DEFAULT '0',
  `corrected_company_number` varchar(255) DEFAULT NULL,
  `manually_updated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_charities_on_charity_number` (`charity_number`),
  KEY `index_charities_on_date_registered` (`date_registered`),
  KEY `index_charities_on_income` (`income`),
  KEY `index_charities_on_spending` (`spending`),
  KEY `index_charities_on_normalised_title` (`normalised_title`(16)),
  KEY `index_charities_on_title` (`title`),
  KEY `index_charities_on_normalised_company_number` (`corrected_company_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table charity_annual_reports
# ------------------------------------------------------------

DROP TABLE IF EXISTS `charity_annual_reports`;

CREATE TABLE `charity_annual_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `charity_id` int(11) DEFAULT NULL,
  `annual_return_code` varchar(255) DEFAULT NULL,
  `financial_year_start` date DEFAULT NULL,
  `financial_year_end` date DEFAULT NULL,
  `income_from_legacies` int(11) DEFAULT NULL,
  `income_from_endowments` int(11) DEFAULT NULL,
  `voluntary_income` int(11) DEFAULT NULL,
  `activities_generating_funds` int(11) DEFAULT NULL,
  `income_from_charitable_activities` int(11) DEFAULT NULL,
  `investment_income` int(11) DEFAULT NULL,
  `other_income` int(11) DEFAULT NULL,
  `total_income` int(11) DEFAULT NULL,
  `investment_gains` int(11) DEFAULT NULL,
  `gains_from_asset_revaluations` int(11) DEFAULT NULL,
  `gains_on_pension_fund` int(11) DEFAULT NULL,
  `voluntary_income_costs` int(11) DEFAULT NULL,
  `fundraising_trading_costs` int(11) DEFAULT NULL,
  `investment_management_costs` int(11) DEFAULT NULL,
  `grants_to_institutions` int(11) DEFAULT NULL,
  `charitable_activities_costs` int(11) DEFAULT NULL,
  `governance_costs` int(11) DEFAULT NULL,
  `other_expenses` int(11) DEFAULT NULL,
  `total_expenses` int(11) DEFAULT NULL,
  `support_costs` int(11) DEFAULT NULL,
  `depreciation` int(11) DEFAULT NULL,
  `reserves` int(11) DEFAULT NULL,
  `fixed_assets_at_start_of_year` int(11) DEFAULT NULL,
  `fixed_assets_at_end_of_year` int(11) DEFAULT NULL,
  `fixed_investment_assets_at_end_of_year` int(11) DEFAULT NULL,
  `fixed_investment_assets_at_start_of_year` int(11) DEFAULT NULL,
  `current_investment_assets` int(11) DEFAULT NULL,
  `cash` int(11) DEFAULT NULL,
  `total_current_assets` int(11) DEFAULT NULL,
  `creditors_within_1_year` int(11) DEFAULT NULL,
  `long_term_creditors_or_provisions` int(11) DEFAULT NULL,
  `pension_assets` int(11) DEFAULT NULL,
  `total_assets` int(11) DEFAULT NULL,
  `endowment_funds` int(11) DEFAULT NULL,
  `restricted_funds` int(11) DEFAULT NULL,
  `unrestricted_funds` int(11) DEFAULT NULL,
  `total_funds` int(11) DEFAULT NULL,
  `employees` int(11) DEFAULT NULL,
  `volunteers` int(11) DEFAULT NULL,
  `consolidated_accounts` tinyint(1) DEFAULT NULL,
  `charity_only_accounts` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_charity_annual_reports_on_charity_id` (`charity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table classification_links
# ------------------------------------------------------------

DROP TABLE IF EXISTS `classification_links`;

CREATE TABLE `classification_links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `classification_id` int(11) DEFAULT NULL,
  `classified_type` varchar(255) DEFAULT NULL,
  `classified_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_classification_links_on_classified_id_and_classified_type` (`classified_id`,`classified_type`),
  KEY `index_classification_links_on_classification_id` (`classification_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table classifications
# ------------------------------------------------------------

DROP TABLE IF EXISTS `classifications`;

CREATE TABLE `classifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `grouping` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `extended_title` mediumtext,
  `uid` varchar(255) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table committees
# ------------------------------------------------------------

DROP TABLE IF EXISTS `committees`;

CREATE TABLE `committees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `description` mediumtext,
  `ward_id` int(11) DEFAULT NULL,
  `normalised_title` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_committees_on_council_id` (`council_id`),
  KEY `index_committees_on_ward_id` (`ward_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table companies
# ------------------------------------------------------------

DROP TABLE IF EXISTS `companies`;

CREATE TABLE `companies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `company_number` varchar(255) DEFAULT NULL,
  `supplier_id` int(11) DEFAULT NULL,
  `normalised_title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `incorporation_date` date DEFAULT NULL,
  `company_type` varchar(255) DEFAULT NULL,
  `wikipedia_url` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `vat_number` varchar(255) DEFAULT NULL,
  `previous_names` mediumtext,
  `sic_codes` mediumtext,
  `country` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table contracts
# ------------------------------------------------------------

DROP TABLE IF EXISTS `contracts`;

CREATE TABLE `contracts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` mediumtext,
  `uid` varchar(255) DEFAULT NULL,
  `source_url` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `organisation_id` int(11) DEFAULT NULL,
  `organisation_type` varchar(255) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `duration` varchar(255) DEFAULT NULL,
  `total_value` int(11) DEFAULT NULL,
  `annual_value` int(11) DEFAULT NULL,
  `supplier_name` varchar(255) DEFAULT NULL,
  `supplier_address` mediumtext,
  `supplier_uid` varchar(255) DEFAULT NULL,
  `department_responsible` varchar(255) DEFAULT NULL,
  `person_responsible` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `telephone` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_contracts_on_organisation_id_and_organisation_type` (`organisation_id`,`organisation_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table council_contacts
# ------------------------------------------------------------

DROP TABLE IF EXISTS `council_contacts`;

CREATE TABLE `council_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `position` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `approved` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_council_contacts_on_council_id` (`council_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table councils
# ------------------------------------------------------------

DROP TABLE IF EXISTS `councils`;

CREATE TABLE `councils` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `base_url` varchar(255) DEFAULT NULL,
  `telephone` varchar(255) DEFAULT NULL,
  `address` mediumtext,
  `authority_type` varchar(255) DEFAULT NULL,
  `portal_system_id` int(11) DEFAULT NULL,
  `notes` mediumtext,
  `wikipedia_url` varchar(255) DEFAULT NULL,
  `ons_url` varchar(255) DEFAULT NULL,
  `egr_id` int(11) DEFAULT NULL,
  `wdtk_name` varchar(255) DEFAULT NULL,
  `feed_url` varchar(255) DEFAULT NULL,
  `data_source_url` varchar(255) DEFAULT NULL,
  `data_source_name` varchar(255) DEFAULT NULL,
  `snac_id` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `population` int(11) DEFAULT NULL,
  `ldg_id` int(11) DEFAULT NULL,
  `os_id` varchar(255) DEFAULT NULL,
  `parent_authority_id` int(11) DEFAULT NULL,
  `police_force_url` varchar(255) DEFAULT NULL,
  `police_force_id` int(11) DEFAULT NULL,
  `ness_id` varchar(255) DEFAULT NULL,
  `lat` float DEFAULT NULL,
  `lng` float DEFAULT NULL,
  `cipfa_code` varchar(255) DEFAULT NULL,
  `region` varchar(255) DEFAULT NULL,
  `signed_up_for_1010` tinyint(1) DEFAULT '0',
  `pension_fund_id` int(11) DEFAULT NULL,
  `gss_code` varchar(255) DEFAULT NULL,
  `annual_audit_letter` varchar(255) DEFAULT NULL,
  `output_area_classification_id` int(11) DEFAULT NULL,
  `defunkt` tinyint(1) DEFAULT '0',
  `open_data_url` varchar(255) DEFAULT NULL,
  `open_data_licence` varchar(255) DEFAULT NULL,
  `normalised_title` varchar(255) DEFAULT NULL,
  `wdtk_id` int(11) DEFAULT NULL,
  `vat_number` varchar(255) DEFAULT NULL,
  `planning_email` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_councils_on_police_force_id` (`police_force_id`),
  KEY `index_councils_on_portal_system_id` (`portal_system_id`),
  KEY `index_councils_on_parent_authority_id` (`parent_authority_id`),
  KEY `index_councils_on_pension_fund_id` (`pension_fund_id`),
  KEY `index_councils_on_output_area_classification_id` (`output_area_classification_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table crime_areas
# ------------------------------------------------------------

DROP TABLE IF EXISTS `crime_areas`;

CREATE TABLE `crime_areas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` varchar(255) DEFAULT NULL,
  `police_force_id` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `level` int(11) DEFAULT NULL,
  `parent_area_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `crime_mapper_url` varchar(255) DEFAULT NULL,
  `feed_url` varchar(255) DEFAULT NULL,
  `crime_level_cf_national` varchar(255) DEFAULT NULL,
  `crime_rates` mediumtext,
  `total_crimes` mediumtext,
  PRIMARY KEY (`id`),
  KEY `index_crime_areas_on_police_force_id` (`police_force_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table crime_types
# ------------------------------------------------------------

DROP TABLE IF EXISTS `crime_types`;

CREATE TABLE `crime_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `plural_name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table data_periods
# ------------------------------------------------------------

DROP TABLE IF EXISTS `data_periods`;

CREATE TABLE `data_periods` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table data_periods_dataset_families
# ------------------------------------------------------------

DROP TABLE IF EXISTS `data_periods_dataset_families`;

CREATE TABLE `data_periods_dataset_families` (
  `data_period_id` int(11) DEFAULT NULL,
  `dataset_family_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table datapoints
# ------------------------------------------------------------

DROP TABLE IF EXISTS `datapoints`;

CREATE TABLE `datapoints` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` double DEFAULT NULL,
  `dataset_topic_id` int(11) DEFAULT NULL,
  `area_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `area_type` varchar(255) DEFAULT NULL,
  `data_period_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_ons_datapoints_on_ons_dataset_topic_id` (`dataset_topic_id`),
  KEY `index_datapoints_on_area_id_and_area_type` (`area_id`,`area_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table dataset_families
# ------------------------------------------------------------

DROP TABLE IF EXISTS `dataset_families`;

CREATE TABLE `dataset_families` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `ons_uid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `source_type` varchar(255) DEFAULT NULL,
  `dataset_id` int(11) DEFAULT NULL,
  `calculation_method` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_dataset_families_on_dataset_id` (`dataset_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table dataset_families_ons_subjects
# ------------------------------------------------------------

DROP TABLE IF EXISTS `dataset_families_ons_subjects`;

CREATE TABLE `dataset_families_ons_subjects` (
  `ons_subject_id` int(11) DEFAULT NULL,
  `dataset_family_id` int(11) DEFAULT NULL,
  KEY `ons_families_subjects_join_index` (`ons_subject_id`,`dataset_family_id`),
  KEY `ons_subjects_families_join_index` (`dataset_family_id`,`ons_subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table dataset_topic_groupings
# ------------------------------------------------------------

DROP TABLE IF EXISTS `dataset_topic_groupings`;

CREATE TABLE `dataset_topic_groupings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `display_as` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `sort_by` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table dataset_topics
# ------------------------------------------------------------

DROP TABLE IF EXISTS `dataset_topics`;

CREATE TABLE `dataset_topics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `ons_uid` int(11) DEFAULT NULL,
  `dataset_family_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `muid` int(11) DEFAULT NULL,
  `description` mediumtext,
  `data_date` date DEFAULT NULL,
  `short_title` varchar(255) DEFAULT NULL,
  `dataset_topic_grouping_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_ons_dataset_topics_on_ons_dataset_family_id` (`dataset_family_id`),
  KEY `index_dataset_topics_on_dataset_topic_grouping_id` (`dataset_topic_grouping_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table datasets
# ------------------------------------------------------------

DROP TABLE IF EXISTS `datasets`;

CREATE TABLE `datasets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` mediumtext,
  `url` varchar(255) DEFAULT NULL,
  `originator` varchar(255) DEFAULT NULL,
  `originator_url` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `dataset_topic_grouping_id` int(11) DEFAULT NULL,
  `notes` mediumtext,
  `licence` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_datasets_on_dataset_topic_grouping_id` (`dataset_topic_grouping_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table delayed_jobs
# ------------------------------------------------------------

DROP TABLE IF EXISTS `delayed_jobs`;

CREATE TABLE `delayed_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `priority` int(11) DEFAULT '0',
  `attempts` int(11) DEFAULT '0',
  `handler` mediumtext,
  `last_error` mediumtext,
  `run_at` datetime DEFAULT NULL,
  `locked_at` datetime DEFAULT NULL,
  `failed_at` datetime DEFAULT NULL,
  `locked_by` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_delayed_jobs_on_priority_and_run_at` (`priority`,`run_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table documents
# ------------------------------------------------------------

DROP TABLE IF EXISTS `documents`;

CREATE TABLE `documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `body` mediumtext,
  `url` varchar(255) DEFAULT NULL,
  `document_owner_id` int(11) DEFAULT NULL,
  `document_owner_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `raw_body` mediumtext,
  `document_type` varchar(255) DEFAULT NULL,
  `precis` mediumtext,
  PRIMARY KEY (`id`),
  KEY `index_documents_on_document_owner_id_and_document_owner_type` (`document_owner_id`,`document_owner_type`),
  KEY `index_documents_on_url` (`url`(64))
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table entities
# ------------------------------------------------------------

DROP TABLE IF EXISTS `entities`;

CREATE TABLE `entities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `entity_type` varchar(255) DEFAULT NULL,
  `entity_subtype` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `wikipedia_url` varchar(255) DEFAULT NULL,
  `sponsoring_organisation` varchar(255) DEFAULT NULL,
  `wdtk_name` varchar(255) DEFAULT NULL,
  `previous_names` mediumtext,
  `setup_on` date DEFAULT NULL,
  `disbanded_on` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `vat_number` varchar(255) DEFAULT NULL,
  `cpid_code` varchar(255) DEFAULT NULL,
  `normalised_title` varchar(255) DEFAULT NULL,
  `other_attributes` mediumtext,
  `external_resource_uri` varchar(255) DEFAULT NULL,
  `telephone` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table feed_entries
# ------------------------------------------------------------

DROP TABLE IF EXISTS `feed_entries`;

CREATE TABLE `feed_entries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `summary` mediumtext,
  `url` varchar(255) DEFAULT NULL,
  `published_at` datetime DEFAULT NULL,
  `guid` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `feed_owner_type` varchar(255) DEFAULT NULL,
  `feed_owner_id` int(11) DEFAULT NULL,
  `lat` double DEFAULT NULL,
  `lng` double DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_feed_entries_on_feed_owner_id_and_feed_owner_type` (`feed_owner_id`,`feed_owner_type`),
  KEY `index_feed_entries_on_guid` (`guid`),
  KEY `index_feed_entries_on_published_at` (`published_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table financial_transactions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `financial_transactions`;

CREATE TABLE `financial_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` mediumtext,
  `uid` varchar(255) DEFAULT NULL,
  `supplier_id` int(11) DEFAULT NULL,
  `date` date DEFAULT NULL,
  `department_name` varchar(255) DEFAULT NULL,
  `service` varchar(255) DEFAULT NULL,
  `cost_centre` varchar(255) DEFAULT NULL,
  `source_url` mediumtext,
  `value` double DEFAULT NULL,
  `transaction_type` varchar(255) DEFAULT NULL,
  `date_fuzziness` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `invoice_number` varchar(255) DEFAULT NULL,
  `csv_line_number` int(11) DEFAULT NULL,
  `classification_id` int(11) DEFAULT NULL,
  `invoice_date` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_financial_transactions_on_supplier_id` (`supplier_id`),
  KEY `index_financial_transactions_on_value` (`value`),
  KEY `index_financial_transactions_on_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table hyperlocal_groups
# ------------------------------------------------------------

DROP TABLE IF EXISTS `hyperlocal_groups`;

CREATE TABLE `hyperlocal_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table hyperlocal_sites
# ------------------------------------------------------------

DROP TABLE IF EXISTS `hyperlocal_sites`;

CREATE TABLE `hyperlocal_sites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `feed_url` varchar(255) DEFAULT NULL,
  `lat` float DEFAULT NULL,
  `lng` float DEFAULT NULL,
  `distance_covered` float DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `hyperlocal_group_id` int(11) DEFAULT NULL,
  `platform` varchar(255) DEFAULT NULL,
  `description` mediumtext,
  `area_covered` varchar(255) DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `approved` tinyint(1) DEFAULT '0',
  `party_affiliation` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_hyperlocal_sites_on_hyperlocal_group_id` (`hyperlocal_group_id`),
  KEY `index_hyperlocal_sites_on_council_id` (`council_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table investigation_subject_connections
# ------------------------------------------------------------

DROP TABLE IF EXISTS `investigation_subject_connections`;

CREATE TABLE `investigation_subject_connections` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `investigation_id` int(11) DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `subject_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_investigation_subject_connections_on_investigation_id` (`investigation_id`),
  KEY `index_investigation_subject_connections_on_subject` (`subject_id`,`subject_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table investigations
# ------------------------------------------------------------

DROP TABLE IF EXISTS `investigations`;

CREATE TABLE `investigations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `related_organisation_name` varchar(255) DEFAULT NULL,
  `raw_html` mediumtext,
  `standards_body` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `subjects` varchar(255) DEFAULT NULL,
  `date_received` date DEFAULT NULL,
  `date_completed` date DEFAULT NULL,
  `description` mediumtext,
  `result` mediumtext,
  `case_details` mediumtext,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `full_report_url` varchar(255) DEFAULT NULL,
  `related_organisation_type` varchar(255) DEFAULT NULL,
  `related_organisation_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_investigations_on_related_organisation` (`related_organisation_id`,`related_organisation_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table ldg_services
# ------------------------------------------------------------

DROP TABLE IF EXISTS `ldg_services`;

CREATE TABLE `ldg_services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` varchar(255) DEFAULT NULL,
  `lgsl` int(11) DEFAULT NULL,
  `lgil` int(11) DEFAULT NULL,
  `service_name` varchar(255) DEFAULT NULL,
  `authority_level` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table meetings
# ------------------------------------------------------------

DROP TABLE IF EXISTS `meetings`;

CREATE TABLE `meetings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date_held` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `committee_id` int(11) DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `venue` mediumtext,
  `status` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_meetings_on_council_id` (`council_id`),
  KEY `index_meetings_on_committee_id` (`committee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table members
# ------------------------------------------------------------

DROP TABLE IF EXISTS `members`;

CREATE TABLE `members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `party` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `telephone` varchar(255) DEFAULT NULL,
  `date_elected` date DEFAULT NULL,
  `date_left` date DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `name_title` varchar(255) DEFAULT NULL,
  `qualifications` varchar(255) DEFAULT NULL,
  `register_of_interests` varchar(255) DEFAULT NULL,
  `address` mediumtext,
  `ward_id` int(11) DEFAULT NULL,
  `blog_url` varchar(255) DEFAULT NULL,
  `facebook_account_name` varchar(255) DEFAULT NULL,
  `linked_in_account_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_members_on_council_id` (`council_id`),
  KEY `index_members_on_ward_id` (`ward_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table memberships
# ------------------------------------------------------------

DROP TABLE IF EXISTS `memberships`;

CREATE TABLE `memberships` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `member_id` int(11) DEFAULT NULL,
  `committee_id` int(11) DEFAULT NULL,
  `date_joined` date DEFAULT NULL,
  `date_left` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_memberships_on_committee_id_and_member_id` (`committee_id`,`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table officers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `officers`;

CREATE TABLE `officers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `name_title` varchar(255) DEFAULT NULL,
  `qualifications` varchar(255) DEFAULT NULL,
  `position` varchar(255) DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_officers_on_council_id` (`council_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table ons_datasets
# ------------------------------------------------------------

DROP TABLE IF EXISTS `ons_datasets`;

CREATE TABLE `ons_datasets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `dataset_family_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_ons_datasets_on_ons_dataset_family_id` (`dataset_family_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table ons_subjects
# ------------------------------------------------------------

DROP TABLE IF EXISTS `ons_subjects`;

CREATE TABLE `ons_subjects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `ons_uid` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table output_area_classifications
# ------------------------------------------------------------

DROP TABLE IF EXISTS `output_area_classifications`;

CREATE TABLE `output_area_classifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `area_type` varchar(255) DEFAULT NULL,
  `level` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table output_areas
# ------------------------------------------------------------

DROP TABLE IF EXISTS `output_areas`;

CREATE TABLE `output_areas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `oa_code` varchar(255) DEFAULT NULL,
  `lsoa_code` varchar(255) DEFAULT NULL,
  `lsoa_name` varchar(255) DEFAULT NULL,
  `ward_id` int(11) DEFAULT NULL,
  `ward_snac_id` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_output_areas_on_ward_id` (`ward_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table parish_councils
# ------------------------------------------------------------

DROP TABLE IF EXISTS `parish_councils`;

CREATE TABLE `parish_councils` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `os_id` varchar(255) DEFAULT NULL,
  `website` text,
  `gss_code` varchar(255) DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `wdtk_name` varchar(255) DEFAULT NULL,
  `vat_number` varchar(255) DEFAULT NULL,
  `normalised_title` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `feed_url` varchar(255) DEFAULT NULL,
  `facebook_account_name` varchar(255) DEFAULT NULL,
  `youtube_account_name` varchar(255) DEFAULT NULL,
  `council_type` varchar(8) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_parish_councils_on_os_id` (`os_id`(16)),
  KEY `index_parish_councils_on_council_id` (`council_id`),
  KEY `index_parish_councils_on_title` (`title`(16))
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table parsers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `parsers`;

CREATE TABLE `parsers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(255) DEFAULT NULL,
  `item_parser` mediumtext,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `attribute_parser` mediumtext,
  `portal_system_id` int(11) DEFAULT NULL,
  `result_model` varchar(255) DEFAULT NULL,
  `related_model` varchar(255) DEFAULT NULL,
  `scraper_type` varchar(255) DEFAULT NULL,
  `path` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `attribute_mapping` mediumtext,
  `skip_rows` int(11) DEFAULT NULL,
  `cookie_path` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_parsers_on_portal_system_id` (`portal_system_id`),
  KEY `index_parsers_on_id_and_type` (`id`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table pension_funds
# ------------------------------------------------------------

DROP TABLE IF EXISTS `pension_funds`;

CREATE TABLE `pension_funds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `telephone` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `fax` varchar(255) DEFAULT NULL,
  `address` mediumtext,
  `wdtk_name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `wdtk_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table planning_alert_subscribers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `planning_alert_subscribers`;

CREATE TABLE `planning_alert_subscribers` (
  `id` int(11) NOT NULL DEFAULT '0',
  `email` varchar(120) NOT NULL,
  `postcode` varchar(10) NOT NULL,
  `digest_mode` tinyint(1) NOT NULL DEFAULT '0',
  `last_sent` datetime DEFAULT NULL,
  `bottom_left_x` int(11) DEFAULT NULL,
  `bottom_left_y` int(11) DEFAULT NULL,
  `top_right_x` int(11) DEFAULT NULL,
  `top_right_y` int(11) DEFAULT NULL,
  `confirm_id` varchar(20) DEFAULT NULL,
  `confirmed` tinyint(1) DEFAULT NULL,
  `alert_area_size` varchar(1) DEFAULT NULL,
  KEY `bottom_left_x` (`bottom_left_x`,`top_right_x`,`bottom_left_y`,`top_right_y`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table planning_alert_subscribers_copy
# ------------------------------------------------------------

DROP TABLE IF EXISTS `planning_alert_subscribers_copy`;

CREATE TABLE `planning_alert_subscribers_copy` (
  `id` int(11) NOT NULL DEFAULT '0',
  `email` varchar(120) NOT NULL,
  `postcode` varchar(10) NOT NULL,
  `digest_mode` tinyint(1) NOT NULL DEFAULT '0',
  `last_sent` datetime DEFAULT NULL,
  `bottom_left_x` int(11) DEFAULT NULL,
  `bottom_left_y` int(11) DEFAULT NULL,
  `top_right_x` int(11) DEFAULT NULL,
  `top_right_y` int(11) DEFAULT NULL,
  `confirm_id` varchar(20) DEFAULT NULL,
  `confirmed` tinyint(1) DEFAULT NULL,
  `alert_area_size` varchar(1) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table planning_applications
# ------------------------------------------------------------

DROP TABLE IF EXISTS `planning_applications`;

CREATE TABLE `planning_applications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` varchar(50) NOT NULL,
  `address` text NOT NULL,
  `postcode` varchar(10) DEFAULT '',
  `description` text,
  `url` varchar(1024) DEFAULT NULL,
  `comment_url` varchar(1024) DEFAULT NULL,
  `retrieved_at` datetime DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `lat` double DEFAULT NULL,
  `lng` double DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `applicant_name` varchar(255) DEFAULT NULL,
  `applicant_address` text,
  `status` varchar(64) DEFAULT NULL,
  `decision` varchar(64) DEFAULT NULL,
  `other_attributes` mediumtext,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `geom` point DEFAULT NULL,
  `application_type` varchar(64) DEFAULT NULL,
  `bitwise_flag` tinyint(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_planning_applications_on_council_id_and_uid` (`council_id`,`uid`),
  KEY `index_planning_applications_on_lat_and_lng` (`lat`,`lng`),
  KEY `index_planning_applications_on_council_id_and_date_received` (`council_id`,`start_date`),
  KEY `index_planning_applications_on_council_id_and_updated_at` (`council_id`,`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table police_authorities
# ------------------------------------------------------------

DROP TABLE IF EXISTS `police_authorities`;

CREATE TABLE `police_authorities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `address` mediumtext,
  `telephone` varchar(255) DEFAULT NULL,
  `wdtk_name` varchar(255) DEFAULT NULL,
  `wikipedia_url` varchar(255) DEFAULT NULL,
  `police_force_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `annual_audit_letter` varchar(255) DEFAULT NULL,
  `vat_number` varchar(255) DEFAULT NULL,
  `wdtk_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_police_authorities_on_police_force_id` (`police_force_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table police_forces
# ------------------------------------------------------------

DROP TABLE IF EXISTS `police_forces`;

CREATE TABLE `police_forces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `wikipedia_url` varchar(255) DEFAULT NULL,
  `telephone` varchar(255) DEFAULT NULL,
  `address` mediumtext,
  `wdtk_name` varchar(255) DEFAULT NULL,
  `npia_id` varchar(255) DEFAULT NULL,
  `youtube_account_name` varchar(255) DEFAULT NULL,
  `facebook_account_name` varchar(255) DEFAULT NULL,
  `feed_url` varchar(255) DEFAULT NULL,
  `crime_map` varchar(255) DEFAULT NULL,
  `wdtk_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table police_officers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `police_officers`;

CREATE TABLE `police_officers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `rank` varchar(255) DEFAULT NULL,
  `biography` mediumtext,
  `police_team_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `index_police_officers_on_police_team_id` (`police_team_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table police_teams
# ------------------------------------------------------------

DROP TABLE IF EXISTS `police_teams`;

CREATE TABLE `police_teams` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `description` mediumtext,
  `url` varchar(255) DEFAULT NULL,
  `police_force_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `lat` double DEFAULT NULL,
  `lng` double DEFAULT NULL,
  `defunkt` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_police_teams_on_police_force_id` (`police_force_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table political_parties
# ------------------------------------------------------------

DROP TABLE IF EXISTS `political_parties`;

CREATE TABLE `political_parties` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `electoral_commission_uid` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `wikipedia_name` varchar(255) DEFAULT NULL,
  `colour` varchar(255) DEFAULT NULL,
  `alternative_names` mediumtext,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table polls
# ------------------------------------------------------------

DROP TABLE IF EXISTS `polls`;

CREATE TABLE `polls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `area_id` int(11) DEFAULT NULL,
  `area_type` varchar(255) DEFAULT NULL,
  `date_held` date DEFAULT NULL,
  `position` varchar(255) DEFAULT NULL,
  `electorate` int(11) DEFAULT NULL,
  `ballots_issued` int(11) DEFAULT NULL,
  `ballots_rejected` int(11) DEFAULT NULL,
  `postal_votes` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `source` varchar(255) DEFAULT NULL,
  `uncontested` tinyint(1) DEFAULT '0',
  `ballots_missing_official_mark` int(11) DEFAULT NULL,
  `ballots_with_too_many_candidates_chosen` int(11) DEFAULT NULL,
  `ballots_with_identifiable_voter` int(11) DEFAULT NULL,
  `ballots_void_for_uncertainty` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_polls_on_area_id_and_area_type` (`area_id`,`area_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table portal_systems
# ------------------------------------------------------------

DROP TABLE IF EXISTS `portal_systems`;

CREATE TABLE `portal_systems` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `notes` mediumtext,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table postcodes
# ------------------------------------------------------------

DROP TABLE IF EXISTS `postcodes`;

CREATE TABLE `postcodes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(255) DEFAULT NULL,
  `quality` int(11) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `nhs_region` varchar(255) DEFAULT NULL,
  `nhs_health_authority` varchar(255) DEFAULT NULL,
  `county_id` int(11) DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `ward_id` int(11) DEFAULT NULL,
  `lat` double DEFAULT NULL,
  `lng` double DEFAULT NULL,
  `crime_area_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_postcodes_on_code` (`code`),
  KEY `index_postcodes_on_ward_id` (`ward_id`),
  KEY `index_postcodes_on_council_id` (`council_id`),
  KEY `index_postcodes_on_county_id` (`county_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table quangos
# ------------------------------------------------------------

DROP TABLE IF EXISTS `quangos`;

CREATE TABLE `quangos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `quango_type` varchar(255) DEFAULT NULL,
  `quango_subtype` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `wikipedia_url` varchar(255) DEFAULT NULL,
  `sponsoring_organisation` varchar(255) DEFAULT NULL,
  `wdtk_name` varchar(255) DEFAULT NULL,
  `previous_names` text,
  `setup_on` date DEFAULT NULL,
  `disbanded_on` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



# Dump of table related_articles
# ------------------------------------------------------------

DROP TABLE IF EXISTS `related_articles`;

CREATE TABLE `related_articles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `subject_type` varchar(255) DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `extract` mediumtext,
  `hyperlocal_site_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_related_articles_on_hyperlocal_site_id` (`hyperlocal_site_id`),
  KEY `index_related_articles_on_subject_id_and_subject_type` (`subject_id`,`subject_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table schema_migrations
# ------------------------------------------------------------

DROP TABLE IF EXISTS `schema_migrations`;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL DEFAULT '',
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table scrapers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `scrapers`;

CREATE TABLE `scrapers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` text,
  `parser_id` int(11) DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `expected_result_class` varchar(255) DEFAULT NULL,
  `expected_result_size` int(11) DEFAULT NULL,
  `expected_result_attributes` mediumtext,
  `type` varchar(255) DEFAULT NULL,
  `related_model` varchar(255) DEFAULT NULL,
  `last_scraped` datetime DEFAULT NULL,
  `problematic` tinyint(1) DEFAULT '0',
  `notes` mediumtext,
  `referrer_url` varchar(255) DEFAULT NULL,
  `cookie_url` varchar(255) DEFAULT NULL,
  `use_post` tinyint(1) DEFAULT '0',
  `parsing_library` varchar(1) DEFAULT 'H',
  `base_url` varchar(255) DEFAULT NULL,
  `next_due` datetime DEFAULT NULL,
  `frequency` tinyint(4) DEFAULT '7',
  `priority` tinyint(4) DEFAULT '4',
  PRIMARY KEY (`id`),
  KEY `index_scrapers_on_id_and_type` (`id`,`type`),
  KEY `index_scrapers_on_parser_id` (`parser_id`),
  KEY `index_scrapers_on_council_id` (`council_id`),
  KEY `index_scrapers_on_priority_and_next_due` (`priority`,`next_due`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table scrapes
# ------------------------------------------------------------

DROP TABLE IF EXISTS `scrapes`;

CREATE TABLE `scrapes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `scraper_id` int(11) DEFAULT NULL,
  `results_summary` varchar(255) DEFAULT NULL,
  `results` text,
  `scraping_errors` text,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_scrapes_on_scraper_id_and_created_at` (`scraper_id`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table services
# ------------------------------------------------------------

DROP TABLE IF EXISTS `services`;

CREATE TABLE `services` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `url` mediumtext,
  `category` varchar(255) DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `ldg_service_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_services_on_council_id` (`council_id`),
  KEY `index_services_on_ldg_service_id` (`ldg_service_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table spending_stats
# ------------------------------------------------------------

DROP TABLE IF EXISTS `spending_stats`;

CREATE TABLE `spending_stats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `organisation_type` varchar(255) DEFAULT NULL,
  `organisation_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `total_spend` double DEFAULT NULL,
  `average_monthly_spend` double DEFAULT NULL,
  `average_transaction_value` double DEFAULT NULL,
  `spend_by_month` mediumtext,
  `breakdown` mediumtext,
  `earliest_transaction` date DEFAULT NULL,
  `latest_transaction` date DEFAULT NULL,
  `transaction_count` bigint(20) DEFAULT NULL,
  `total_received_from_councils` int(11) DEFAULT NULL,
  `payer_breakdown` text,
  `total_received` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_spending_stats_on_organisation` (`organisation_id`,`organisation_type`),
  KEY `index_spending_stats_on_organisation_type_and_total_spend` (`organisation_type`,`total_spend`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table stats
# ------------------------------------------------------------

DROP TABLE IF EXISTS `stats`;

CREATE TABLE `stats` (
  `key` varchar(25) NOT NULL,
  `value` int(11) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



# Dump of table suppliers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `suppliers`;

CREATE TABLE `suppliers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `organisation_type` varchar(255) DEFAULT NULL,
  `organisation_id` int(11) DEFAULT NULL,
  `failed_payee_search` tinyint(1) DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `payee_id` int(11) DEFAULT NULL,
  `payee_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_suppliers_on_organisation_id_and_organisation_type` (`organisation_id`,`organisation_type`),
  KEY `index_suppliers_on_payee_id_and_payee_type` (`payee_id`,`payee_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table taggings
# ------------------------------------------------------------

DROP TABLE IF EXISTS `taggings`;

CREATE TABLE `taggings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tag_id` int(11) DEFAULT NULL,
  `taggable_id` int(11) DEFAULT NULL,
  `tagger_id` int(11) DEFAULT NULL,
  `tagger_type` varchar(255) DEFAULT NULL,
  `taggable_type` varchar(255) DEFAULT NULL,
  `context` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_taggings_on_tag_id` (`tag_id`),
  KEY `index_taggings_on_taggable_id_and_taggable_type_and_context` (`taggable_id`,`taggable_type`,`context`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table tags
# ------------------------------------------------------------

DROP TABLE IF EXISTS `tags`;

CREATE TABLE `tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table twitter_accounts
# ------------------------------------------------------------

DROP TABLE IF EXISTS `twitter_accounts`;

CREATE TABLE `twitter_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_type` varchar(255) DEFAULT NULL,
  `twitter_id` int(11) DEFAULT NULL,
  `follower_count` int(11) DEFAULT NULL,
  `following_count` int(11) DEFAULT NULL,
  `last_tweet` mediumtext,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_twitter_accounts_on_user_id_and_user_type` (`user_id`,`user_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table user_submissions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `user_submissions`;

CREATE TABLE `user_submissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `twitter_account_name` varchar(255) DEFAULT NULL,
  `item_id` int(11) DEFAULT NULL,
  `member_id` int(11) DEFAULT NULL,
  `member_name` varchar(255) DEFAULT NULL,
  `blog_url` varchar(255) DEFAULT NULL,
  `facebook_account_name` varchar(255) DEFAULT NULL,
  `linked_in_account_name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `approved` tinyint(1) DEFAULT '0',
  `submission_details` mediumtext,
  `item_type` varchar(255) DEFAULT NULL,
  `ip_address` varchar(255) DEFAULT NULL,
  `notes` mediumtext,
  PRIMARY KEY (`id`),
  KEY `index_user_submissions_on_member_id` (`member_id`),
  KEY `index_user_submissions_on_council_id` (`item_id`),
  KEY `index_user_submissions_on_item_id_and_item_type` (`item_id`,`item_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table wards
# ------------------------------------------------------------

DROP TABLE IF EXISTS `wards`;

CREATE TABLE `wards` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `council_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `snac_id` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `os_id` varchar(255) DEFAULT NULL,
  `police_neighbourhood_url` varchar(255) DEFAULT NULL,
  `ness_id` varchar(255) DEFAULT NULL,
  `gss_code` varchar(255) DEFAULT NULL,
  `police_team_id` int(11) DEFAULT NULL,
  `output_area_classification_id` int(11) DEFAULT NULL,
  `defunkt` tinyint(1) DEFAULT '0',
  `crime_area_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_wards_on_council_id` (`council_id`),
  KEY `index_wards_on_police_team_id` (`police_team_id`),
  KEY `index_wards_on_output_area_classification_id` (`output_area_classification_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table wdtk_requests
# ------------------------------------------------------------

DROP TABLE IF EXISTS `wdtk_requests`;

CREATE TABLE `wdtk_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `description` mediumtext,
  `organisation_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `organisation_type` varchar(255) DEFAULT NULL,
  `uid` int(11) DEFAULT NULL,
  `related_object_type` varchar(255) DEFAULT NULL,
  `related_object_id` int(11) DEFAULT NULL,
  `request_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_wdtk_requests_on_council_id` (`organisation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

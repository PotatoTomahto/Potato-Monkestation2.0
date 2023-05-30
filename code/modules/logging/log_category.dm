/// The main datum that contains all log entries for a category
/datum/log_category
	/// The category this datum contains
	var/category
	/// If set this config flag is checked to enable this log category
	var/config_flag

	/// Whether or not this log should not be publically visible
	var/secret = FALSE

	/// Whether the readable version of the log message is formatted internally instead of by rustg
	var/internal_formatting = TRUE

	/// List of log entries for this category
	var/list/entries = list()

	/// Total number of entries this round so far
	var/entry_count = 0

GENERAL_PROTECT_DATUM(/datum/log_category)

/// Backup log category to catch attempts to log to a category that doesn't exist
/datum/log_category/backup_category_not_found
	category = LOG_CATEGORY_NOT_FOUND

/// Add an entry to this category. It is very important that any data you provide doesn't hold references to anything!
/datum/log_category/proc/add_entry(message, list/data)
	var/list/entry = list(
		LOG_ENTRY_MESSAGE = message,
		LOG_ENTRY_TIMESTAMP = big_number_to_text(rustg_unix_timestamp()),
	)
	if(data)
		entry[LOG_ENTRY_DATA] = data

	entries += list(entry)
	write_entry(entry)
	entry_count += 1
	if(entry_count <= CONFIG_MAX_CACHED_LOG_ENTRIES)
		entries += entry

/// Allows for category specific file splitting. Needs to accept a null entry for the default file.
/datum/log_category/proc/get_output_file(list/entry)
	return "[GLOB.log_directory]/[category].json"

/// Writes an entry to the output file for the category
/datum/log_category/proc/write_entry(list/entry)
	rustg_file_append("[json_encode(entry)]\n", get_output_file(entry))

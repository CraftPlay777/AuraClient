// Luanti
// SPDX-License-Identifier: LGPL-2.1-or-later
// Copyright (C) 2010-2013 celeron55, Perttu Ahola <celeron55@gmail.com>

#include "texturepaths.h"

#include "util/container.h"
#include "util/thread.h"
#include "settings.h"
#include "filesys.h"
#include "porting.h"
#include <vector>

// A cache from texture name to texture path
static MutexedMap<std::string, std::string> g_texturename_to_path_cache;
// Cached result of getTextureDirs()
static MutexedVariable<std::vector<std::string>> g_texturedirs_cache;
// AuraClient: buscar la skin local.
// Devuelve una ruta solo si hay exactamente un PNG.
static std::string getAuraLocalSkin()
{
    const std::string folders[] = {
        porting::path_user + DIR_DELIM "skin",
        porting::path_share + DIR_DELIM "skin"
    };

    for (const std::string &folder : folders) {
        if (!fs::IsDir(folder))
            continue;

        std::string selected;
        int count = 0;

        for (const auto &entry : fs::GetDirListing(folder)) {
            if (entry.dir)
                continue;

            const std::string &name = entry.name;

            if (name.size() < 4 ||
                    name.substr(name.size() - 4) != ".png")
                continue;

            ++count;
            selected = folder + DIR_DELIM + name;
        }

        if (count == 1)
            return selected;

        if (count > 1)
            return "";
    }

    return "";
}

void clearTextureNameCache()
{
	g_texturename_to_path_cache.clear();
	g_texturedirs_cache.set({});
}

// Find out the full path of an image by trying different filename extensions.
// If failed, return "".
std::string getImagePath(std::string_view path)
{
	// possible image extensions
	static const char *extensions[] = {".png", ".jpg", ".tga", nullptr};

	// Remove present extension
	std::string_view stripped_path = removeStringEnd(path, extensions);
	// If there is no known extension, assume it has been omitted.
	if (stripped_path.empty())
		stripped_path = path;

	for (const char *ext : extensions) {
		if (!ext)
			break;
		std::string extended_path(stripped_path);
		extended_path.append(ext);
		if (fs::PathExists(extended_path))
			return extended_path;
	}

	return "";
}

/* Gets the path to a texture by first checking if the texture exists
 * in texture_path and if not, using the data path.
 *
 * Checks all supported extensions by replacing the original extension.
 *
 * If not found, returns "".
 *
 * Utilizes a thread-safe cache.
*/
std::string getTexturePath(const std::string &filename, bool *is_base_pack)
{
    // AuraClient: nombre reservado para la skin del jugador local.
    if (filename == "auraclient_local_skin.png") {
        if (is_base_pack)
            *is_base_pack = false;

        return getAuraLocalSkin();
    }

    std::string fullpath;

	// This can set a wrong value on cached textures, but is irrelevant because
	// is_base_pack is only passed when initializing the textures the first time
	if (is_base_pack)
		*is_base_pack = false;

	// Check from cache
	bool incache = g_texturename_to_path_cache.get(filename, &fullpath);
	if (incache)
		return fullpath;

	// Check from texture_path setting
	for (const auto &path : getTextureDirs()) {
		// Check all filename extensions. Returns "" if not found.
		fullpath = getImagePath(path + DIR_DELIM + filename);
		if (!fullpath.empty())
			break;
	}

	// Check from default data directory
	if (fullpath.empty()) {
		std::string base_path = porting::path_share + DIR_DELIM "textures"
				DIR_DELIM "base" DIR_DELIM "pack";
		// Check all filename extensions. Returns "" if not found.
		fullpath = getImagePath(base_path + DIR_DELIM + filename);
		if (is_base_pack && !fullpath.empty())
			*is_base_pack = true;
	}

	// Add to cache (an empty result is cached too)
	g_texturename_to_path_cache.set(filename, fullpath);

	return fullpath;
}

std::vector<std::string> getTextureDirs()
{
	std::vector<std::string> ret = g_texturedirs_cache.get();
	if (ret.empty()) {
		ret = fs::GetRecursiveDirs(g_settings->get("texture_path"));
		g_texturedirs_cache.set(ret);
	}
	return ret;
}

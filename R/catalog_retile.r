# ===============================================================================
#
# PROGRAMMERS:
#
# jean-romain.roussel.1@ulaval.ca  -  https://github.com/Jean-Romain/lidR
#
# COPYRIGHT:
#
# Copyright 2016 Jean-Romain Roussel
#
# This file is part of lidR R package.
#
# lidR is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# ===============================================================================


#' Retile a catalog
#'
#' This function splits or merges files to reshape the original catalog files (.las or .laz)
#' into smaller or larger files. It also enables to add or remove buffer around the tiles.
#' The new files are written in a dedicated folder. The function first displays the pattern of the new
#' tiling pattern and then asks the user to validate the command.
#'
#' The internal processing options of a \code{LAScatalog} drive the way the catalog is retiled. See
#' \link{catalog}
#'
#' @param ctg  A \link[lidR:catalog]{LAScatalog} object
#' @param path string. The folder where the new files should be saved.
#' @param prefix character. The initial part of the name of the written files. It can be missing and if
#' the catalog is processed by files the original name of the file will be retained.
#' @param ext character. The format of the written files. Can be ".las" or ".laz".
#'
#' @return A new \code{LAScatalog} object
#' @seealso \link{catalog}
#' @export
#' @examples
#' \dontrun{
#' ctg = catalog("path/to/catalog")
#'
#' # Create a new set of .las files 500 by 500 wide in the folder
#' # path/to/new/catalog/ and iteratively named Forest_001.las, Forest_002.las
#' # Forest_003.las, and so on.
#'
#' buffer(ctg) = 0
#' by_file(ctg) = FALSE
#' tiling_size(ctg) = 500
#' newctg = catalog_reshape(ctg, "path/to/new/catalog", "Forest_")
#'
#' # Create a new set of .las files equivalent to the original one but extended with
#' # a 50 m buffer in the folder path/to/new/catalog/ and iteratively named Forest_001.las, Forest_002.las
#' # Forest_003.las, and so on.
#'
#' buffer(ctg) = 50
#' by_file(ctg) = TRUE
#' newctg = catalog_reshape(ctg, "path/to/new/catalog", "Forest_")
#' }
catalog_retile = function(ctg, path, prefix, ext = c("las", "laz"))
{
  assertive::assert_is_all_of(ctg, "LAScatalog")
  assertive::is_character(path)

  if(!missing(prefix))
    assertive::is_character(prefix)
  else
    prefix = ""

  format           <- match.arg(ext)
  interact         <- LIDROPTIONS("interactive")
  ncores           <- cores(ctg)
  progress         <- progress(ctg)
  stopearly        <- stop_early(ctg)

  clusters <- catalog_makecluster(ctg, 1)

  for (i in 1:length(clusters))
  {
    if (by_file(ctg) && prefix == "")
      clusters[[i]]@name <- tools::file_path_sans_ext(basename(ctg@data$filename[i]))
    else
      clusters[[i]]@name <- sprintf("%05d", as.numeric(i))
  }

  if(interact)
  {
    text = "This is how the catalog will be reshaped (see plots). Do you want to continue?"
    choices = c("yes","no")

    cat(text)
    choice = utils::menu(choices)

    if (choice == 2)
      return(invisible(NULL))
  }

  if(!dir.exists(path))
    dir.create(path, recursive = TRUE)

  files <- list.files(path, pattern = "(?i)\\.la(s|z)$")

  if(length(files) > 0)
    stop("The output folder already contains .las or .laz files. Operation aborted.", call. = FALSE)

  cluster_apply(clusters, reshape_func, ncores, progress, stopearly, path = path, prefix = prefix, ext = format)

  return(catalog(path))
}

reshape_func = function(cluster, path, prefix, ext)
{
  ofile = paste0(path, "/", prefix, cluster@name , ".", ext)
  streamLAS(cluster, ofile)

  header = rlas::read.lasheader(ofile)

  if (header$`Number of point records` == 0)
  {
    file.remove(ofile)
    return(NULL)
  }

  return(0)
}

# ================= OLD ===================== #

#' Reshape (retile) a catalog
#'
#' This function is supersed by \link{catalog_retile} that can do the same and much more.
#'
#' @param ctg  A \link[lidR:catalog]{LAScatalog} object
#' @param size scalar. The size of the new tiles.
#' @param path string. The folder where the new files should be saved.
#' @param prefix character. The initial part of the name of the written files.
#' @param ext character. The format of the written files. Can be ".las" or ".laz".
#'
#' @return A new catalog object
#' @seealso \link{catalog}
#' @export
#' @examples
#' \dontrun{
#' ctg = catalog("path/to/catalog")
#'
#' # Create a new set of .las files 500 by 500 wide in the folder
#' # path/to/new/catalog/ and iteratively named Forest_1.las, Forest_2.las
#' # Forest_3.las, and so on.
#' newctg = catalog_reshape(ctg, 500, "path/to/new/catalog", "Forest_")
#' }
catalog_reshape = function(ctg, size, path, prefix, ext = c("las", "laz"))
{
  assertive::assert_is_all_of(ctg, "LAScatalog")
  assertive::assert_is_a_number(size)
  assertive::assert_all_are_positive(size)
  assertive::is_character(path)
  assertive::is_character(prefix)

  format           <- match.arg(ext)
  interact         <- LIDROPTIONS("interactive")
  buffer(ctg)      <- 0
  by_file(ctg)     <- FALSE
  tiling_size(ctg) <- size
  ncores           <- cores(ctg)
  progress         <- progress(ctg)
  stopearly        <- stop_early(ctg)

  clusters <- catalog_makecluster(ctg, 1)

  if(interact)
  {
    text = "This is how the catalog will be reshaped. Do you want to continue?"
    choices = c("yes","no")

    cat(text)
    choice = utils::menu(choices)

    if (choice == 2)
      return(invisible(NULL))
  }

  if(!dir.exists(path))
    dir.create(path, recursive = TRUE)

  files <- list.files(path, pattern = "(?i)\\.la(s|z)$")

  if(length(files) > 0)
    stop("The output folder already contains .las or .laz files. Operation aborted.", call. = FALSE)

  cluster_apply(clusters, reshape_func, ncores, progress, stopearly, path = path, prefix = prefix, ext = format)

  return(catalog(path))
}
% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/algorithm-its.R
\name{watershed}
\alias{watershed}
\alias{mcwatershed}
\title{Individual Tree Segmentation Algorithm}
\usage{
watershed(chm, th_tree = 2, tol = 1, ext = 1)

mcwatershed(chm, treetops, th_tree = 2, ID = "treeID")
}
\arguments{
\item{chm}{RasterLayer. Image of the canopy. Can be computed with \link{grid_canopy} or read from
an external file.}

\item{th_tree}{numeric. Threshold below which a pixel cannot be a tree. Default is 2.}

\item{tol}{numeric. Tolerance see ?EBImage::watershed.}

\item{ext}{numeric. see ?EBImage::watershed.}

\item{treetops}{\code{SpatialPointsDataFrame}. Can be computed with
\link{find_trees} or read from an external shapefile.}

\item{ID}{character. If the \code{SpatialPointsDataFrame} contains an attribute with the ID for
each tree, the name of this column. This way, original IDs will be preserved. If there is no such
data trees will be numbered sequentially.}
}
\description{
This function is made to be used in \link{segment_trees}. It implements an algorithm for tree
segmentation based on a watershed or a marker-controlled watershed.
\itemize{
\item \strong{Simple watershed} is based on the bioconductor package \code{EBIimage}. You need to install
this package to run this method (see its \href{https://github.com/aoles/EBImage}{github page}).
Internally, the function EBImage::watershed is called.
\item \strong{Marker-controlled watershed} is based on the \code{imager} package and has been removed
because \code{imager} is an orphaned package.
}
}
\details{
Because this algorithm works on a CHM only there is no actual need for a point cloud. Sometimes the
user does not even have the point cloud that generated the CHM. \code{lidR} is a point cloud-oriented
library, which is why this algorithm must be used in \link{segment_trees} to merge the result into the point
cloud. However, the user can use this as a stand-alone function like this:
\preformatted{
 chm = raster("file/to/a/chm/")
 ttops = find_trees(chm, lmf(3))
 crowns = watershed(chm)()
}
}
\examples{
LASfile <- system.file("extdata", "MixedConifer.laz", package="lidR")
las <- readLAS(LASfile, select = "xyz", filter = "-drop_z_below 0")
col <- pastel.colors(250)

chm <- grid_canopy(las, res = 0.5, p2r(0.3))
ker <- matrix(1,3,3)
chm <- raster::focal(chm, w = ker, fun = mean, na.rm = TRUE)
las <- segment_trees(las, watershed(chm))

plot(las, color = "treeID", colorPalette = col)
}
\seealso{
Other individual tree segmentation algorithms: 
\code{\link{dalponte2016}()},
\code{\link{li2012}()},
\code{\link{silva2016}()}

Other raster based tree segmentation algorithms: 
\code{\link{dalponte2016}()},
\code{\link{silva2016}()}
}
\concept{individual tree segmentation algorithms}
\concept{raster based tree segmentation algorithms}

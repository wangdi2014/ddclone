### decay functions and distance functions

indexed.window.decay <- function(dat, threshold) {
  function(i) {
    as.integer(dat[i] <= threshold)
  }
}

window.decay <- function(w) {
  function (x) {
    as.integer(x <= w)
  }
}

window.decay.s <- function(x, w) {
  as.integer(x <= w)# || x >=(1-w))
}

logistic.decay.s <- function(x, a, b=.1) {
 logistic((-x+a)/b)
}

logistic.decay <- function(a, b=1)
  function (x) logistic((-x+a)/b)

exp.decay <- function(a, b = 1.0)
  function (x) exp(-x/a) * b + 1e-6

exp.decay.s <- function(x, a, b = 1) {
  exp(-x/a) * b + 1e-6
}


# TODO: change back to 1
identity.decay <- function (x, dummy)
{
  ifelse(x == Inf, 0, 1)
}

euclidean.dist <- function(p1, p2)
{
  v <- p1 - p2
  sqrt(v %*% v)
}

manhattan.dist <- function(p1, p2)
{
  v <- abs((p1[1] - p2[1])) + abs((p1[2] - p2[2]))
}

subtract.dist <- function(p1, p2)
{
  p1 - p1
}

seq.dist <- function(i,j)
{
  if (j <= i)
    i - j
  else
    Inf
}

input.based.dist.fn <- function(input, dist.fn)
{
  function (i,j) { dist.fn(input[i], input[j]) }
}

matrix.dist.fn <- function(dist.matrix)
{
  function (i,j) {
    dist.matrix[i,j]
  }
}

link.dist.fn <- function(adj)
{
  function (i, j) if (adj[i,j]==0) { Inf } else { 1 }
}

#' Standard Jaccard distance
#' @param sDat should be a list containing an element  \code{filteredMutMatrix}, the genotype (or cell) by mutation matrix
#' @param Options should be empty
#' @return A matrix whose elements are the distances between the loci
#' @export
jaccardDist <- function(sDat, options=NULL) {
  d <- as.matrix(vegan::vegdist(t(sDat$filteredMutMatrix), method='jaccard', na.rm = T))
  if (nrow(sDat$filteredMutMatrix) == 1) {
    d <- as.matrix(vegan::vegdist(t(sDat$filteredMutMatrix), method='euclidean', na.rm = F))
  }
  d[which(is.nan(d))] <- 1
  d
}


identity.s <- function(simulatedData, options=NULL) {
  d <- matrix(NA, nrow=ncol(simulatedData$filteredMutMatrix), ncol=ncol(simulatedData$filteredMutMatrix))

  for (i in seq(nrow(d))) {
    for (j in seq(ncol(d))) {
      d[i, j] <- Inf
      if (i == j) d[i, j] <- 2
      else if (i > j) d[i, j] <- i - j
    }
  }
  d
}


mean.size <- function(X, FN.rate) {
  sum(X) + (length(X) - sum(X)) * FN.rate
}


# For binary vectors X and Y,
# define a as the number of times where exactly one of X_i or Y_i are equal to 1
# define b as the number of times that both X_i and Y_i are equal to 1.
# The modified Jaccard distance is (a + 2*b*FN.rate)/(a+b)
modified.jaccard.dist.vector <- function(X, Y, FN.rate) {
  XplusY <- mean.size(X, FN.rate) + mean.size(Y, FN.rate)
  XintersectY <- sum(xor(X, Y))*FN.rate + sum(X & Y)
  (XplusY - 2*XintersectY) / (XplusY - XintersectY)
}


#' A non-symmeteric jaccard distance with respect to FN and FP rates
#' @param sDat a list containing an element  \code{filteredMutMatrix}, the genotype (or cell) by mutation matrix
#' @param Options is a list containing an element FN.rate, the estimated false negative rate, FN.rate is mostly contributed to by adoRate
#' @return A matrix whose elements are the distances between the loci
#' @export
modified.jaccard.dist <- function(sDat, options = NULL) {
  if (!is.null(options)) {
    if (is.null(options$FN.rate))
      FN.rate <- 0
    else
      FN.rate <- options$FN.rate
  }
  if (FN.rate == 0 || nrow(sDat$filteredMutMatrix) == 1) return(jaccardDist(sDat))

  # initialize the dist mat
  mat <- sDat$filteredMutMatrix
  d <- matrix(data = NA, ncol(mat), ncol(mat))
  colnames(d) <- colnames(mat)
  rownames(d) <- colnames(mat)

  for (i in 1:(ncol(mat) -1) ) {
    for (j in (i+1):ncol(mat)) {
      d[i, j] <- modified.jaccard.dist.vector(mat[, i], mat[, j], FN.rate)
      d[j, i] <- d[i, j]
    }
  }

  for (i in 1:(ncol(mat))) {
    d[i, i] <- 0
  }

  d[which(is.nan(d))] <- 1
  d
}



cosineDist <- function(simulatedData) {
  as.matrix(cosine(simulatedData$filteredMutMatrix))
}


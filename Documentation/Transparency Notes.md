How to do Transparency
======================

With the whole change with Metal, it's a good time to reevaluate how blending
works in GLLara, because the way it currently does is hacky and sucks. For the
new approach, the goals are:

-   Correct in z-Order
-   As many draw calls as it takes
-   Don't think too much about render time until it becomes a problem.

Proposal
--------

-   Every item mesh gets an array of triangle centroids. One centroid per triangle, in global space
-   On any bone update this array gets recomputed (TODO: Do we need to store it at all?)
-   Array is stored as SOA format, i.e. one X array, one Y, one Z.
-   On drawing:
    1.  For each mesh:
        -   New array: Distance along camera axis; make use of SOA structure here
        -   New array: Indices, starts out as 0…n
        -   Sort Indices array based on corresponding distances
        -   Record visible range, which may be empty.
    2.  Entire scene:
        -   Global array of index, mesh (possibly two of them?)
        -   Another sort stage. Make sure to use stable sort.
        -   Go through, draw
            -   Take advantage of fact that large ranges should be the same
            -   And we can submit arrays to MTL without uploading buffers
            

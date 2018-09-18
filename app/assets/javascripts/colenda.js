renderViewer = function() {
    imagesArray = jQuery.parseJSON($("#pages").attr("data"));
    assetsHash = jQuery.parseJSON($("#navImages").attr("data"));
    var viewer = OpenSeadragon({
        id: "openseadragon",
        prefixUrl: '',
        showNavigator:  true,
        navigatorPosition:   "TOP_RIGHT",
        sequenceMode:       true,
        showReferenceStrip: true,
        collectionMode:       false,
        collectionRows:       4,
        collectionTileSize:   200,
        collectionTileMargin: 10,
        collectionLayout:     'vertical',
        showRotationControl: true,
        referenceStripScroll: "horizontal",
        tileSources: imagesArray,
        navImages: assetsHash
    });
    return viewer;
}
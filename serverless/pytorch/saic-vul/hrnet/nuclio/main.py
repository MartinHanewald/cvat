# Copyright (C) 2021 Intel Corporation
#
# SPDX-License-Identifier: MIT

import json
import base64
from typing import List
from PIL import Image
import io
from model_handler import ModelHandler


def init_context(context):
    context.logger.info("Init context...  0%")

    model = ModelHandler()
    context.user_data.model = model

    context.logger.info("Init context...100%")


def handler(context, event):
    context.logger.info("call handler")
    data = event.body
    pos_points = data["pos_points"]
    neg_points = data["neg_points"]
    threshold = data.get("threshold", 0.5)
    buf = io.BytesIO(base64.b64decode(data["image"]))
    image = Image.open(buf)
    # context.logger.info(f"pos_points: {pos_points}")
    # context.logger.info(f"neg_points: {neg_points}")
    tile = enveloping_tile(pos_points, neg_points)
    if tile:
        context.logger.info(f"Enveloping tile: {tile}")
        image = image.crop(tile)
        # subtract tile coordinates from points
        pos_points = [(x - tile[0], y - tile[1]) for x, y in pos_points]
        neg_points = [(x - tile[0], y - tile[1]) for x, y in neg_points]

    polygon = context.user_data.model.handle(image, pos_points, neg_points, threshold)

    # add tile xmin and ymin to polygon
    if tile:
        polygon = [(x + tile[0], y + tile[1]) for x, y in polygon]
    context.logger.info(f"Polygon: {polygon}")

    return context.Response(
        body=json.dumps(polygon),
        headers={},
        content_type="application/json",
        status_code=200,
    )


def enveloping_tile(pos_points, neg_points, margin=250) -> List:

    points = pos_points + neg_points
    if not points:
        return []
    x_min, x_max = (
        min(points, key=lambda x: x[0])[0],
        max(points, key=lambda x: x[0])[0],
    )
    y_min, y_max = (
        min(points, key=lambda x: x[1])[1],
        max(points, key=lambda x: x[1])[1],
    )
    tile = (x_min - margin, y_min - margin, x_max + margin, y_max + margin)
    return tile

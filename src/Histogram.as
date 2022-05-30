funcdef vec4 HistogramBarColor(uint, float);

vec4 NullBarColor(uint x, float halfBucketWidth) {
    return vec4(1, 1, 1, 1);
}

namespace Histogram {
    const vec4 BG_COL = vec4(.1, .1, .1, .75);

    void Draw(
            vec2 uvPos, vec2 uvSize,
            uint[]&in rawData, uint nBuckets,
            HistogramBarColor@ barColorF = NullBarColor
            ) {
        /** */
        float sw = Draw::GetWidth();
        float sh = Draw::GetHeight();
        vec2 pos = uvPos * vec2(sw, sh);
        vec2 size = uvSize * vec2(sw, sh);

        /* draw the BG first -- we can show some feedback before exiting if no data passed in. */

        nvg::Reset();

        // draw bg
        nvg::BeginPath();
        nvg::Rect(pos.x, pos.y, size.x, size.y);
        nvg::FillColor(BG_COL);
        nvg::Fill();
        nvg::ClosePath();

        /* now draw histogram */

        /* parameters of histogram */
        rawData.SortAsc();

        if (rawData.Length == 0) {
            // todo: no data msg?
            return;
        }

        uint minRawD = rawData[0];
        uint maxRawD = rawData[rawData.Length - 1];
        uint xSpan = maxRawD - minRawD;

        if (xSpan == 0) {
            return;
        }

        float bucketWidth = float(xSpan) / float(nBuckets);
        // trace("min: " + minRawD + ", max: " + maxRawD);

        /* organize data */
        // todo: need to do bucket allocation properly
        uint[] data = array<uint>(nBuckets + 1);
        for (uint i = 0; i < rawData.Length; i++) {
            uint v = rawData[i];
            uint _d = v - minRawD;
            uint bucketIx = Math::Floor(_d / bucketWidth);
            if (bucketIx > nBuckets + 1) {
                warn("Histogram::Draw] Calculated bucketIx outside range: " + bucketIx + " _d=" + _d + " bucketWidth=" + bucketWidth);
                continue;
            }
            data[bucketIx]++;
        }

        /* scale relative to max population in bucket */
        uint maxCount = 0;
        uint bucketIxOfMax = 0;
        for (uint i = 0; i < data.Length; i++) {
            if (data[i] > maxCount) {
                maxCount = data[i];
                bucketIxOfMax = i;
            }
        }

        float barWidth = size.x / float(nBuckets + 1);
        /* draw each bar */
        for (uint b = 0; b <= nBuckets; b++) {
            float height = size.y * float(data[b]) / float(maxCount);
            uint xScore = uint(b * bucketWidth) + minRawD;
            DrawBar(pos.x + barWidth * b, pos.y + size.y, barWidth, -height, barColorF(xScore, bucketWidth / 2));
        }

#if DEV
        if (false && Time::Now % 1000 < (1000 / 60)) {
            print("Histogram Data");
            print("minRawD: " + minRawD);
            print("maxRawD: " + maxRawD);
            print("bucketWidth: " + bucketWidth);
            print("barWidth: " + barWidth);
            print("maxCount: " + maxCount);
            print("bucketIxOfMax: " + bucketIxOfMax);
            print("data[bucketIxOfMax]: " + data[bucketIxOfMax]);
            print("data[0]: " + data[0]);
            print("data[10]: " + data[10]);
            print("data[20]: " + data[20]);
            print("data[30]: " + data[30]);
        }
#endif
    }

    void DrawBar(float x, float y, float w, float h, vec4 col) {
        nvg::BeginPath();
        nvg::Rect(x, y, w, h);
        nvg::FillColor(col);
        nvg::Fill();
        nvg::ClosePath();
    }
}

namespace Histogram {
    funcdef vec4 BarColor(uint, float);
    funcdef string XLabelFmt(uint x);

    /* function defaults for parameters to Draw */

    vec4 NullBarColor(uint x, float halfBucketWidth) {
        return vec4(1, 1, 1, 1);
    }

    string TimeXLabelFmt(uint x) {
        return x > 0 ? Time::Format(x) : "-:--.---";
    }

    /* Main drawing */

    const vec4 BG_COL = vec4(.1, .1, .1, .5);
    const vec4 _WHITE = vec4(1, 1, 1, 1);
    const vec4 _BLACK = vec4(0, 0, 0, 1);

    Resources::Font@ labelFont = Resources::GetFont("DroidSans.ttf", 20, -1, -1, true, true);;

    void Draw(
            vec2 uvPos, vec2 uvSize,
            int2 minMaxRank,
            // uint[] &in rawData, uint nBuckets,
            BarColor@ barColorF = NullBarColor,
            XLabelFmt@ xLabelFmt = TimeXLabelFmt
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
        nvg::FillColor(BG_COL * (sTabHudHistogramActive.Either() ? 3. : 1.));
        nvg::Fill();
        nvg::ClosePath();

        /* Are we a preview? */

        if (sTabHudHistogramActive.Either()) {
            DrawBiggerTitle("COTD HISTOGRAM\nPREVIEW", vec2(pos.x, pos.y + .2 * size.y), size);
        }

        /* now draw histogram */

        /* parameters of histogram */
        // auto hData = RawDataToHistData(rawData, nBuckets);
        auto hData = DataManager::cotd_HistogramData;
        if (hData is null) {
            DrawTitle("No Data", vec2(pos.x, pos.y + .8 * size.y), size);
            return;
        }
        auto data = hData.ys;
        auto bucketWidth = hData.bucketWidth;
        auto nBuckets = data.Length - 1;

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
            uint xScore = uint(b * bucketWidth + hData.minXVal);
            DrawBar(pos.x + barWidth * b, pos.y + size.y, barWidth, -height, barColorF(xScore, bucketWidth / 2));
        }

        /* draw X min/max labels */
        string leftXL = xLabelFmt(uint(hData.minXVal));
        string rightXL = xLabelFmt(uint(hData.maxXVal));
        DrawLabelBelow(leftXL, pos + vec2(barWidth/2., size.y));
        DrawLabelBelow(rightXL, pos + size - vec2(barWidth/2., 0));

        /* draw title */
        auto t = "Ranks " + minMaxRank.x + " to " + minMaxRank.y;
        // auto t = DataManager::GetChallengeTitle() + " (" + ranksStr + ")";
        DrawTitle(t, pos, size);

        _DebugPrintVariables(hData, barWidth, maxCount, bucketIxOfMax);
    }

    void DrawBar(float x, float y, float w, float h, vec4 col) {
        nvg::BeginPath();
        nvg::Rect(x, y, w, h);
        nvg::FillColor(col);
        nvg::Fill();
        nvg::ClosePath();
    }

    const float _TB_WIDTH = 200;

    void DrawLabelBelow(string &in l, vec2 pos) {
        /* set up */
        auto dh = Draw::GetHeight() * 0.01;
        auto lSize = Draw::MeasureString(l , labelFont, 20, _TB_WIDTH) * 1.3;
        auto lPos = pos - vec2(1.05 * lSize.x / 2, lSize.y * 0.115 - dh);  /* 0.115 = (1-1/1.3)/2

        /* bg rect */
        nvg::FillColor(BG_COL * vec4(1,1,1,.7));
        nvg::BeginPath();
        nvg::Rect(lPos.x, lPos.y, lSize.x, lSize.y);
        nvg::Fill();
        nvg::ClosePath();

        /* label */
        nvg::FillColor(_WHITE);
        nvg::FontFace(labelFont);
        nvg::FontSize(20);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
        nvg::TextBox(pos.x - lSize.x / 2., pos.y + dh + lSize.y / 2., lSize.x, l);

        /* tick mark */
        nvg::StrokeColor(_BLACK);
        nvg::StrokeWidth(.5);
        nvg::BeginPath();
        nvg::Rect(pos.x - 1, pos.y, 1.5, dh * .6);
        nvg::Fill();
        // nvg::Stroke();
        nvg::ClosePath();
    }

    /* the pos and size are for the main window */
    void DrawTitle(string &in t, vec2 pos, vec2 size) {
        _DrawTitle(t, pos, size, size.y / 8.);
    }

    void DrawBiggerTitle(string &in t, vec2 pos, vec2 size) {
        _DrawTitle(t, pos, size, size.y / 4.);
    }

    void _DrawTitle(string &in t, vec2 pos, vec2 size, float fontSize) {
        nvg::FillColor(_WHITE);
        nvg::FontFace(labelFont);
        nvg::FontSize(fontSize);
        nvg::TextAlign(nvg::Align::Center | nvg::Align::Top);
        nvg::TextBox(pos.x, pos.y + size.y * 0.05, size.x, t);
        // nvg::Fill();
    }

    class HistData {
        uint[] m_ys;
        uint m_minXVal;
        uint m_maxXVal;
        float m_bucketWidth;
        HistData(uint[] &in ys, float minXVal, float maxXVal, float bucketWidth) {
            m_ys = ys;
            m_minXVal = uint(minXVal);
            m_maxXVal = uint(maxXVal);
            m_bucketWidth = bucketWidth;
        }
        HistData(uint[] &in ys, uint minXVal, uint maxXVal, float bucketWidth) {
            m_ys = ys;
            m_minXVal = minXVal;
            m_maxXVal = maxXVal;
            m_bucketWidth = bucketWidth;
        }
        uint[] get_ys() { return m_ys; }
        float get_bucketWidth() { return m_bucketWidth; }
        float get_minXVal() { return m_minXVal; }
        float get_maxXVal() { return m_maxXVal; }
    }

    HistData@ RawDataToHistData(uint[] &in rawData, uint nBuckets) {
        rawData.SortAsc();

        if (rawData.Length == 0) {
            // todo: no data msg?
            return null;
        }

        uint minRawD = 0;
        uint startIx = 0;
        for (startIx = 0; minRawD == 0 && startIx < rawData.Length; startIx++) {
            minRawD = rawData[startIx];
        }
        startIx--;
        // if (minRawD > 0) {
        //     warn("minRawD=" + minRawD + "; rawData[startIx]=" + rawData[startIx]
        //         + "; rawData[startIx-1]=" + rawData[startIx-1]
        //         + "; rawData[startIx-2]=" + rawData[startIx-2]);
        // }
        uint maxRawD = rawData[rawData.Length - 1];
        uint xSpan = maxRawD - minRawD;

        if (xSpan == 0) {
            return null;
        }

        float bucketWidth = float(xSpan) / float(nBuckets);
        // trace("min: " + minRawD + ", max: " + maxRawD);

        /* organize data */
        // todo: need to do bucket allocation properly
        uint[] data = array<uint>(nBuckets + 1);
        for (uint i = 0; i < rawData.Length; i++) {
            uint v = rawData[i];
            if (v == 0) { continue; }
            uint _d = v - minRawD;
            uint bucketIx = uint(Math::Floor(_d / bucketWidth));
            if (bucketIx > nBuckets + 1) {
                warn("Histogram::Draw] Calculated bucketIx outside range: " + bucketIx + " _d=" + _d + " bucketWidth=" + bucketWidth);
                continue;
            }
            data[bucketIx]++;
        }
        return HistData(data, minRawD, maxRawD, bucketWidth);
    }



    void _DebugPrintVariables(HistData@ hData, float barWidth, uint maxCount, uint bucketIxOfMax) {
#if DEV
        if (false && Time::Now % 1000 < (1000 / 60)) {
            print("Histogram Data");
            print("hData.minXVal: " + hData.minXVal);
            print("hData.maxXVal: " + hData.maxXVal);
            print("hData.bucketWidth: " + hData.bucketWidth);
            print("barWidth: " + barWidth);
            print("maxCount: " + maxCount);
            print("bucketIxOfMax: " + bucketIxOfMax);
            print("hData.ys[bucketIxOfMax]: " + hData.ys[bucketIxOfMax]);
            print("hData.ys[0]: " + hData.ys[0]);
            print("hData.ys[10]: " + hData.ys[10]);
            print("hData.ys[20]: " + hData.ys[20]);
            print("hData.ys[30]: " + hData.ys[30]);
        }
#endif
    }
}

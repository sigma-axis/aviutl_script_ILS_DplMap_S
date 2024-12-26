--[[
MIT License
Copyright (c) 2024 sigma-axis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

https://mit-license.org/
]]

--
-- VERSION: v1.00
--

--------------------------------

local ils = require "InlineScene_S";
local obj, math, tonumber = obj, math, tonumber;

-- an upvalue storage of setting values.
local settings = {
	x = 0.0,
	y = 0.0,
	angle = 0.0,
	size = 200,
	scale = -1,
	aspect = 0.0,
};

local function settings_common(x, y, angle, aspect)
	settings.x = tonumber(x) or 0;
	settings.y = tonumber(y) or 0;
	settings.angle = tonumber(angle) or 0;
	settings.size = -1;
	settings.scale = -1;
	settings.aspect = math.min(math.max(tonumber(aspect) or 0, -1), 1);
end
---マップ元画像の配置情報を記録する．拡大率指定のタイプ．
---@param x number? 中央の点の X 座標．ピクセル単位で，既定値は 0.
---@param y number? 中央の点の Y 座標．ピクセル単位で，既定値は 0.
---@param angle number? 回転角度を度数法で指定．時計回りに正，既定値は 0.
---@param scale number? マップ元画像の拡大率を指定，既定値は等倍で 1.0.
---@param aspect number? マップ元画像の縦横比を指定．値は -1.0 から +1.0 で，正で縦長，負で横長．
local function settings_byscale(x, y, angle, scale, aspect)
	settings_common(x, y, angle, aspect);
	settings.scale = math.max(tonumber(scale) or 1, 0);
end
---マップ元画像の配置情報を記録する．サイズ指定のタイプ．
---@param x number? 中央の点の X 座標．ピクセル単位で，既定値は 0.
---@param y number? 中央の点の Y 座標．ピクセル単位で，既定値は 0.
---@param angle number? 回転角度を度数法で指定．時計回りに正，既定値は 0.
---@param size number? マップ元画像のサイズを長辺の長さでピクセル単位で指定．既定値は 200.
---@param aspect number? マップ元画像の縦横比を指定．値は -1.0 から +1.0 で，正で縦長，負で横長．
local function settings_bysize(x, y, angle, size, aspect)
	settings_common(x, y, angle, aspect);
	settings.size = math.max(tonumber(size) or 200, 0);
end

---"Inline scene" をマップ元画像としたディスプレイスメントマップを適用する．計算中に tempbuffer を上書きするため，必要ならデータの退避をしておくこと．
---@param name string マップ元画像に利用する "inline scene" の名前．(赤: def_x に影響，緑: def_y に影響)
---@param def_1 number ディスプレイスメントマップの第1変形パラメタ (X移動 / 水平拡大 / 回転角度).
---@param def_2 number ディスプレイスメントマップの第2変形パラメタ (Y移動 / 垂直拡大).
---@param deform integer ディスプレイスメントマップの変形の種類．1: 移動変形，2: 拡大変形，3: 回転変形．
---@param blur number マップ元画像のぼかし量．ピクセル単位．
---@param curr_frame boolean? 現在フレームで合成された "inline scene" のみを対象にするかどうかを指定．既定値は `false`.
---@param recall_settings boolean? `settings_byscale` などで指定された設定を有効化する．false の場合は「元のサイズに合わせる」が ON の場合の挙動．
local function apply(name, def_1, def_2, deform, blur, curr_frame, recall_settings)
	-- hereafter in this function, "source" is the image that defines the mapping for deformations,
	-- and "target" is the one that is being deformed.
	-- "source" is only meaningful with its R, G and A channels.

	if def_1 == 0 and (deform == 3 or def_2 == 0) then return end

	local cache_name, metrics, status, _ = ils.read_cache(name);
	if not status or (curr_frame and status ~= "new") then return end

	-- calculate the source placement.
	local fit_size, x, y, angle, size, aspect = true, 0, 0, 0, 200, 0;
	if recall_settings then
		fit_size = false;
		x, y = settings.x, settings.y;
		angle = settings.angle + metrics.rz;

		-- determine sizing.
		local scale;
		scale, aspect = ils.combine_aspect(metrics.zoom, metrics.aspect, settings.aspect);
		if settings.size < 0 then
			scale = scale * settings.scale;
		else
			scale = settings.size / math.max(
				metrics.w * math.min(1 - metrics.aspect, 1),
				metrics.h * math.min(1 + metrics.aspect, 1));
		end
		size = math.floor(0.5 + scale * math.max(metrics.w, metrics.h));
		if size <= 0 then return end -- not effective.
		scale = size / math.max(metrics.w, metrics.h);

		-- adjust the position and rotation center according to the current states.
		local base_cx, base_cy = obj.getvalue("cx"), obj.getvalue("cy");
		x, y = x - obj.ox + obj.cx - base_cx, y - obj.oy + obj.cy - base_cy;
		if ils.offscreen_drawn() then
			x, y = x + obj.x - base_cx, y + obj.y - base_cy;
		end

		-- apply rotation and scaling.
		local src_cx, src_cy = metrics.cx, metrics.cy;
		if aspect > 0 then src_cx = (1 - aspect) * src_cx;
		elseif aspect < 0 then src_cy = (1 + aspect) * src_cy end
		src_cx, src_cy = scale * src_cx, scale * src_cy;

		if angle % 360 ~= 0 then
			local c, s = math.cos(math.pi / 180 * angle), math.sin(math.pi / 180 * angle);
			src_cx, src_cy = c * src_cx - s * src_cy, s * src_cx + c * src_cy;
		end
		x, y = x - src_cx, y - src_cy;
	end

	-- apply displacement mapping.
	obj.copybuffer("tmp", cache_name);
	obj.effect("ディスプレイスメントマップ", "type", 0, "name", "*tempbuffer",
		"param0", def_1,"param1", def_2, "calc", deform - 1, "ぼかし", blur,
		"元のサイズに合わせる", fit_size and 1 or 0,
		"X", x, "Y", y, "回転", angle, "サイズ", size, "縦横比", 100 * aspect);
end

local function equals_any(x, y, ...)
	if y == nil then return false;
	elseif x == y then return true;
	else return equals_any(x, ...) end
end
---直前のフィルタ効果が同じファイルの指定のスクリプトであることを確認する関数．付属の `.anm` 専用の用途・目的．
---@param ... string アニメーション効果名を列挙．
---@return boolean
local function is_former_script(...)
	local s = obj.getoption("script_name", -1, true);
	if s then
		local t = obj.getoption("script_name"):match("@.+$");
		if #t < #s and s:sub(-#t) == t then
			return equals_any(s:sub(1, -#t - 1), ...);
		end
	end
	return false;
end

return {
	settings_byscale = settings_byscale,
	settings_bysize = settings_bysize,

	apply = apply,

	is_former_script = is_former_script,
};

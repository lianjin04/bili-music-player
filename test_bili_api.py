#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""B站公开 API 连通性测试（无需 Cookie）"""

import json
import sys
import traceback
from datetime import datetime, timezone
from typing import Any, Dict
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

BASE = "https://api.bilibili.com"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                  "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
    "Referer": "https://www.bilibili.com/",
    "Accept": "application/json, text/plain, */*",
}

UP_MID = "424571864"
MEDIA_ID = "789827364"
EXPECTED_FOLDERS = {"默认收藏夹", "课", "音乐"}


def get_json(path: str, params: Dict[str, Any] | None = None) -> Dict[str, Any]:
    url = BASE + path
    if params:
        url += "?" + urlencode(params)
    req = Request(url, headers=HEADERS, method="GET")
    with urlopen(req, timeout=20) as resp:
        raw = resp.read().decode("utf-8")
        return json.loads(raw)


def assert_bili_ok(name: str, data: Dict[str, Any]) -> None:
    code = data.get("code")
    if code != 0:
        raise AssertionError(f"{name} 返回 code={code}, message={data.get('message')!r}, ttl={data.get('ttl')!r}")


def main() -> int:
    lines: list[str] = []

    def log(msg: str) -> None:
        print(msg)
        lines.append(msg)

    log("B站公开 API 连通性测试")
    log(f"时间: {datetime.now(timezone.utc).isoformat()}")
    log("")

    try:
        # 测试1：获取用户公开收藏夹列表
        log("[测试1] 获取用户公开收藏夹列表")
        folders_resp = get_json("/x/v3/fav/folder/created/list-all", {"up_mid": UP_MID})
        assert_bili_ok("收藏夹列表", folders_resp)
        folders = folders_resp.get("data", {}).get("list", []) or []
        folder_titles = {f.get("title") for f in folders}
        log(f"  获取收藏夹数量: {len(folders)}")
        log(f"  收藏夹名称: {', '.join(str(x) for x in folder_titles)}")
        missing = EXPECTED_FOLDERS - folder_titles
        if missing:
            raise AssertionError(f"缺少预期收藏夹: {', '.join(missing)}")
        log("  ✅ 验证通过：包含「默认收藏夹」「课」「音乐」")
        log("")

        # 测试2：获取公开收藏夹视频列表
        log("[测试2] 获取公开收藏夹视频列表")
        resources_resp = get_json("/x/v3/fav/resource/list", {
            "media_id": MEDIA_ID,
            "pn": 1,
            "ps": 5,
            "platform": "web",
        })
        assert_bili_ok("收藏夹视频列表", resources_resp)
        medias = resources_resp.get("data", {}).get("medias", []) or []
        log(f"  获取视频数量: {len(medias)}")
        if not medias:
            raise AssertionError("收藏夹视频列表为空")
        first = medias[0]
        checks = {
            "bvid": first.get("bvid"),
            "title": first.get("title"),
            "upper.name": (first.get("upper") or {}).get("name"),
            "duration": first.get("duration"),
            "cover": first.get("cover"),
        }
        for key, value in checks.items():
            if value in (None, ""):
                raise AssertionError(f"视频字段缺失或为空: {key}; first={json.dumps(first, ensure_ascii=False)[:1000]}")
        bvid = first["bvid"]
        log(f"  首个视频: {first.get('title')} ({bvid})")
        log(f"  UP主字段 upper.name: {checks['upper.name']}")
        log("  ✅ 验证通过：包含 bvid, title, upper.name, duration, cover")
        log("")

        # 测试3：获取视频信息
        log("[测试3] 获取视频信息并提取 cid")
        view_resp = get_json("/x/web-interface/view", {"bvid": bvid})
        assert_bili_ok("视频信息", view_resp)
        cid = view_resp.get("data", {}).get("cid")
        if not cid:
            raise AssertionError(f"cid 缺失: {json.dumps(view_resp, ensure_ascii=False)[:1000]}")
        log(f"  bvid={bvid}, cid={cid}")
        log("  ✅ 验证通过：cid 存在")
        log("")

        # 测试4：获取音频流地址
        log("[测试4] 获取音频流地址")
        play_resp = get_json("/x/player/playurl", {
            "bvid": bvid,
            "cid": cid,
            "qn": 128,
            "fnver": 0,
            "fnval": 4048,
            "platform": "web",
            "otype": "json",
        })
        assert_bili_ok("音频流地址", play_resp)
        audio = (((play_resp.get("data") or {}).get("dash") or {}).get("audio") or [])
        if not audio:
            raise AssertionError(f"dash.audio 为空: {json.dumps(play_resp, ensure_ascii=False)[:1000]}")
        base_url = audio[0].get("baseUrl") or audio[0].get("base_url")
        if not base_url:
            raise AssertionError(f"dash.audio[0].baseUrl/base_url 缺失: {json.dumps(audio[0], ensure_ascii=False)[:1000]}")
        log(f"  音频流数量: {len(audio)}")
        log(f"  baseUrl 前缀: {base_url[:120]}...")
        log("  ✅ 验证通过：dash.audio[0].baseUrl 存在")
        log("")

        log("结论: ✅ 全部测试通过")
        return 0
    except (AssertionError, HTTPError, URLError, TimeoutError, Exception) as exc:
        log("")
        log("结论: ❌ 测试失败")
        log(f"错误: {type(exc).__name__}: {exc}")
        log("Traceback:")
        tb = traceback.format_exc()
        print(tb)
        lines.append(tb)
        return 1
    finally:
        with open("test_result.txt", "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    sys.exit(main())

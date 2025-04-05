import asyncio
from enum import Enum
from typing import Optional

from flet.core.control import Service, control
from flet.core.control_event import ControlEvent
from flet.core.types import (
    OptionalControlEventCallable,
    OptionalEventCallable,
    OptionalNumber,
)


class ReleaseMode(Enum):
    RELEASE = "release"
    LOOP = "loop"
    STOP = "stop"


class AudioState(Enum):
    STOPPED = "stopped"
    PLAYING = "playing"
    PAUSED = "paused"
    COMPLETED = "completed"
    DISPOSED = "disposed"


class AudioStateChangeEvent(ControlEvent):
    state: AudioState


class AudioPositionChangeEvent(ControlEvent):
    position: int


class AudioDurationChangeEvent(ControlEvent):
    duration: int


@control("Audio")
class Audio(Service):
    """
    A control to simultaneously play multiple audio files. Works on macOS, Linux, Windows, iOS, Android and web. Based on audioplayers Flutter widget (https://pub.dev/packages/audioplayers).

    Audio control is non-visual and should be added to `page.overlay` list.

    Example:
    ```
    import flet as ft

    import flet_audio as fta

    def main(page: ft.Page):
        audio1 = fta.Audio(
            src="https://luan.xyz/files/audio/ambient_c_motion.mp3", autoplay=True
        )
        page.overlay.append(audio1)
        page.add(
            ft.Text("This is an app with background audio."),
            ft.ElevatedButton("Stop playing", on_click=lambda _: audio1.pause()),
        )

    ft.app(target=main)
    ```

    -----

    Online docs: https://flet.dev/docs/controls/audio
    """

    src: Optional[str] = None
    src_base64: Optional[str] = None
    autoplay: bool = False
    volume: OptionalNumber = None
    balance: OptionalNumber = None
    playback_rate: OptionalNumber = None
    release_mode: Optional[ReleaseMode] = None
    on_loaded: OptionalControlEventCallable = None
    on_duration_changed: OptionalEventCallable[AudioDurationChangeEvent] = None
    on_state_changed: OptionalEventCallable[AudioStateChangeEvent] = None
    on_position_changed: OptionalEventCallable[AudioPositionChangeEvent] = None
    on_seek_complete: OptionalControlEventCallable = None

    async def play_async(self):
        await self._invoke_method_async("play")

    def play(self):
        asyncio.create_task(self.play_async())

    async def pause_async(self):
        await self._invoke_method_async("pause")

    def pause(self):
        asyncio.create_task(self.pause_async())

    async def resume_async(self):
        await self._invoke_method_async("resume")

    def resume(self):
        asyncio.create_task(self.resume_async())

    async def release_async(self):
        await self._invoke_method_async("release")

    def release(self):
        asyncio.create_task(self.release_async())

    async def seek_async(self, position_milliseconds: int):
        await self._invoke_method_async("seek", {"position": position_milliseconds})

    def seek(self, position_milliseconds: int):
        asyncio.create_task(self.seek_async(position_milliseconds))

    async def get_duration_async(self) -> Optional[int]:
        return await self._invoke_method_async("get_duration")

    async def get_current_position_async(
        self, wait_timeout: Optional[float] = 5
    ) -> Optional[int]:
        return await self._invoke_method_async("get_current_position")

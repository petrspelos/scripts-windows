# VideoPreviewMaker

This utility generates a preview `.gif` file from a video similar to for example YouTube video previews.

## USAGE:

> ℹ - A published version of the application might run faster

- Generate a 4 frame `.gif` preview where each frame lasts 1 second

```
dotnet run ./my-video.mp4
```

- Keep individual frame `.png` files after processing is done

```
dotnet run ./my-video.mp4 --keep-frame-files
```

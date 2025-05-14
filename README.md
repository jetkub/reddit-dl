# Reddit Video Downloader

**Backstory:** I wanted to share a meme I saw on Reddit's PrequelMemes subreddit. [This one](https://old.reddit.com/r/PrequelMemes/comments/fp280f/this_is_my_magnum_opus_my_creme_de_la_creme/). Reddit does not make it easy to simply download and share a video file. I would prefer to share an actual file instead of a link to Reddit, whose website and mobile client is now incredibly poor in my experience. My Reddit client of choice, Apollo, provided this awesome functionality: direct video sharing. The app would export the video to a file when you attempted to share the post. If I recall correctly, the behavior was configurable in the app preferences. Ever since that app went defunct in 2023, I've stopped using Reddit. However, I knew there were a few high quality memes on there that I wanted to save and share. Therefore, I set out to put something together and I now had a good excuse to try Ruby.

**Note:** This is a work-in-progress and an incredibly naive implementation because I just wanted to get something working. This isn't a mature project.

## Usage
```
./reddit-dl.rb <reddit-post-url>
./reddit-dl.rb -p [destination directory] <reddit-post-url>
```
### Requirements
You will need ruby installed. There is also one dependency that is not part of the standard library. Therefore, you will need to install it:
```
gem install nokigiri
```

## Limitations
This script will not download videos from Reddit posts in which the video is not hosted on Reddit (v.redd.it). Video hosts such as imgur.com are not (yet?) supported.

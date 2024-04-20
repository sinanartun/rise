import os
import av
from PIL import Image, ImageDraw, ImageFont
from av.stream import Stream
import json
import textwrap
import boto3
import requests
from botocore.exceptions import ClientError, NoCredentialsError, PartialCredentialsError
import time
import subprocess

def download_image(image_url):
    try:
        response = requests.get(image_url)
        if response.status_code == 200:
            with open('/tmp/background_origin_{video_id}.png', 'wb') as f:  
                f.write(response.content)
        else:
            print(f"Failed to download image from URL: {image_url}")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

def get_item_from_dynamodb():
    session = boto3.Session(

        region_name='eu-north-1'
    )
    dynamodb = session.client('dynamodb', region_name='eu-north-1')

    try:
        response = dynamodb.get_item(TableName='wojak', Key={'id': {'S': video_id}})
        if 'Item' in response:
            item = response['Item']
            return item
        else:
            return "No item found with ID: {}".format(video_id)
    except ClientError as e:
        print(e.response['Error']['Message'])
        return "Error accessing DynamoDB: {}".format(e.response['Error']['Message'])


def upload_file_to_s3(file_name, bucket_name, object_name=None):

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = file_name

    # Create an S3 client
    s3_client = boto3.client('s3')

    try:
        # Upload the file
        s3_client.upload_file(file_name, bucket_name, object_name)
        print("File uploaded successfully.")
        return True
    except FileNotFoundError:
        print("The file was not found.")
        return False
    except NoCredentialsError:
        print("Credentials not available.")
        return False
    except PartialCredentialsError:
        print("Incomplete credentials.")
        return False


def crop_image():
    image_path = f'/tmp/background_origin_{video_id}.png'
    with Image.open(image_path) as img:
        img_width, img_height = img.size
        left = (img_width - 1080) / 2
        top = (img_height - 1350) / 2
        right = (img_width + 1080) / 2
        bottom = (img_height + 1350) / 2
        left = max(0, left)
        top = max(0, top)
        right = min(img_width, right)
        bottom = min(img_height, bottom)
        img_cropped = img.crop((left, top, right, bottom))
        img_resized = img_cropped.resize((1080, 1350), Image.LANCZOS)
        output_path = f'/tmp/background_{video_id}.png'
        img_resized.save(output_path)




def add_mp3_to_video():
    video_path = f'/tmp/video_nosound_{video_id}.mp4'
    audio_path = 'music.mp3'
    output_path = f'/tmp/video_{video_id}.mp4'
    command = [
        'ffmpeg',
        '-i', video_path,
        '-stream_loop', '-1',
        '-i', audio_path,
        '-shortest',
        '-map', '0:v:0',
        '-map', '1:a:0',
        '-c:v', 'copy',
        '-y',
        output_path
    ]
    try:
        subprocess.run(command, check=True)
        print(f"Video and audio have been successfully merged into {output_path}")
    except subprocess.CalledProcessError as e:
        print("Failed to merge video and audio:", e)

def generate_subtitle_image(text, index):
    font_path = 'impact.ttf'
    background_path = f'/tmp/backgroud_{video_id}.png'
    face_paths = ['face1.png', 'monster.png']
    video_stream_width = 1080
    video_stream_height = 1350
    image = Image.open(background_path)
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(font_path, 60)
    face_image = Image.open(face_paths[index % len(face_paths)])
    face_image = face_image.resize((400, 400))  # Resize the face image
    face_x = 100 if (index % len(face_paths)) != 1 else video_stream_width - 500
    face_y = video_stream_height - 500
    image.paste(face_image, (face_x, face_y), face_image)
    wrapper = textwrap.TextWrapper(width=40)
    wrapped_text = wrapper.wrap(text)
    shadow_color = 'black'
    shadow_offset = (2, 2) 

    text_y = 120
    for line in wrapped_text:
        bbox = draw.textbbox((0, text_y), line, font=font)
        text_width = bbox[2] - bbox[0]
        text_x = (video_stream_width - text_width) // 2
        draw.text((text_x + shadow_offset[0], text_y + shadow_offset[1]), line, font=font, fill=shadow_color)
        draw.text((text_x, text_y), line, font=font, fill='white')
        text_y += (bbox[3] - bbox[1]) + 20

    return image


def create_video():
    with open('/temp/subtitle_{video_id}.json', 'w') as file:
        subtitles_data = json.load(file)
        container = av.open(f'/tmp/video_nosound_{video_id}.mp4', mode='w')
        video_stream = container.add_stream('mpeg4', rate=1)
        video_stream.width = 1080
        video_stream.height = 1350
        video_stream.pix_fmt = 'yuv420p'
        
        pts = 0
        for index, subtitle in enumerate(subtitles_data):
            image = generate_subtitle_image(subtitle['line'], index)
            frame = av.VideoFrame.from_image(image)
            frame.pts = pts
            for packet in video_stream.encode(frame):
                container.mux(packet)
            pts += 3

        for packet in video_stream.encode():
            container.mux(packet)
        container.close()




video_id = ''
def main(event, context):
    video_id = event.get('video_id','ygCW0CWO')
    item =get_item_from_dynamodb('ygCW0CWO')
    image_url_s = item.get('image_url')
    image_url = image_url_s['S']
    script   = item.get('script')
    data = json.loads(script['S'])
    print(data)
    
    download_image(image_url)
    time.sleep(1)
    crop_image()
    time.sleep(1)
    create_video()
    time.sleep(1)
    add_mp3_to_video()
    time.sleep(1)
    upload_file_to_s3(f'/tmp/video_{video_id}.mp4', 'helloafrica', f'video_{video_id}.mp4')
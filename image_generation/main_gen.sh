#!/bin/bash

TOTAL_WORKERS=8
IMAGES_PER_WORKER=6250
export BLENDER=/home/lena/blender-2.78b-linux-glibc219-x86_64

echo "=== Проверка состояния и запуск воркеров ==="

for i in $(seq 0 $((TOTAL_WORKERS - 1)))
do
  # Вычисляем жесткие границы диапазона для текущего воркера
  WORKER_MIN_IDX=$(( i * IMAGES_PER_WORKER ))
  WORKER_MAX_IDX=$(( WORKER_MIN_IDX + IMAGES_PER_WORKER - 1 ))
  
  OUT_DIR="clevr_v2/out_$i"
  
  # Считаем количество уже готовых .json файлов в папке воркера
  # Исключаем общий файл CLEVR_scenes.json, если он там есть
  if [ -d "$OUT_DIR" ]; then
    JSON_COUNT=$(find "$OUT_DIR" -maxdepth 1 -name "CLEVR_train_*.json" | wc -l)
  else
    JSON_COUNT=0
  fi

  # Вычисляем, сколько картинок осталось сгенерировать этому воркеру
  NUM_IMAGES=$(( IMAGES_PER_WORKER - JSON_COUNT ))

  # Если воркер уже выполнил свою норму, пропускаем его
  if [ $NUM_IMAGES -le 0 ]; then
    echo "Воркер $i: Полностью завершен ($JSON_COUNT/$IMAGES_PER_WORKER файлов)."
    continue
  fi

  # Определяем start_idx
  if [ $JSON_COUNT -eq 0 ]; then
    # Если файлов нет, начинаем с самого начала диапазона воркера
    START_IDX=$WORKER_MIN_IDX
  else
    # Ищем файл с максимальным индексом в названии
    # Пример имени: CLEVR_train_043750.json -> вырезаем '043750' -> убираем ведущие нули -> находим max
    MAX_CURRENT_IDX=$(find "$OUT_DIR" -maxdepth 1 -name "CLEVR_train_*.json" | \
      grep -oE '[0-9]{6}' | sed 's/^0*//' | sort -rn | head -n 1)
    
    # Если строка оказалась пустой (на всякий случай), страхуемся
    if [ -z "$MAX_CURRENT_IDX" ]; then
      START_IDX=$WORKER_MIN_IDX
    else
      START_IDX=$(( MAX_CURRENT_IDX + 1 ))
    fi
  fi

  echo "Воркер $i: Готово $JSON_COUNT из $IMAGES_PER_WORKER. Запуск: num_images=$NUM_IMAGES, start_idx=$START_IDX"

  # Запуск блендера для текущего воркера в фоновом режиме (&)
  $BLENDER/blender --background --python render_images.py -- \
    --num_images $NUM_IMAGES \
    --start_idx $START_IDX \
    --output_image_dir "$OUT_DIR/images" \
    --output_scene_dir "$OUT_DIR" \
    --output_scene_file "$OUT_DIR/CLEVR_scenes_$i.json" \
    --split train \
    --margin 0.4 \
    --min_dist 0.5 \
    --width 256 \
    --height 256 \
    --render_num_samples 128 \
    --camera_jitter 0.0 \
    --key_light_jitter 0.0 \
    --fill_light_jitter 0.0 \
    --back_light_jitter 0.0 &

done

echo "--------------------------------------------------"
echo "Все незавершенные воркеры запущены параллельно в фоне."
echo "Используйте 'jobs' или 'ps aux | grep blender' для отслеживания."

# Ожидаем завершения всех фоновых процессов
wait
echo "Все воркеры успешно завершили работу!"
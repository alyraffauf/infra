resource "b2_bucket" "aly_anime" {
  bucket_name = "aly-anime"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_apps" {
  bucket_name = "aly-apps"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_archive" {
  bucket_name = "aly-archive"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 60
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_audiobooks" {
  bucket_name = "aly-audiobooks"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_backups" {
  bucket_name = "aly-backups"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_camera" {
  bucket_name = "aly-camera"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_code" {
  bucket_name = "aly-code"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_forgejo" {
  bucket_name = "aly-forgejo"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 1
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_movies" {
  bucket_name = "aly-movies"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_music" {
  bucket_name = "aly-music"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 3
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_outline" {
  bucket_name = "aly-outline"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_shows" {
  bucket_name = "aly-shows"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_sync" {
  bucket_name = "aly-sync"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

resource "b2_bucket" "aly_tranquil_blobs" {
  bucket_name = "aly-tranquil-blobs"
  bucket_type = "allPrivate"
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }
  lifecycle_rules {
    days_from_hiding_to_deleting = 7
    file_name_prefix             = ""
  }
}

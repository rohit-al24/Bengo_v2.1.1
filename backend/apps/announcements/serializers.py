from rest_framework import serializers

from .models import Announcement


class AnnouncementSerializer(serializers.ModelSerializer):
    image = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = Announcement
        fields = [
            'id',
            'title',
            'description',
            'image',
            'is_active',
            'link_enabled',
            'link_url',
            'button_text',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get('request')
        if request and data.get('image'):
            data['image'] = request.build_absolute_uri(data['image'])
        return data
